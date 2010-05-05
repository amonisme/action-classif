classdef LSVM < ClassifierAPI
    % Latent SVM
    
    properties
        class_names
        models
        n_components  % number of component in the mixture model  
        n_parts       % number of parts
        overlap_th    % force detection to overlap the annotated bounding box
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function [pos, neg] = make_examples(Ipaths, flippedpos, class_ids, id)
            n_img = numel(Ipaths);
            
            w = zeros(n_img,1);
            bb = zeros(n_img, 4);
            trunc = zeros(n_img,1);            
            for i=1:n_img
                [bb_not_cropped bb width] = get_bb_info(Ipaths{i});
                w(i) = width;
                trunc(i) = bb(1);
                bb = bb(2:end);
            end
            trunc = logical(trunc);
            
            if flippedpos
                p = find(class_ids == id);
                n_pos = length(p);
                pos = struct('im', cell(n_pos*2,1), 'flip', false, 'x1', 0, 'y1', 0, 'x2', 0, 'y2', 0);
                for i = 1:n_pos                   
                    x1 = bb(p(i),1);
                    x2 = bb(p(i),3);
                    pos(2*i-1).im = Ipaths{p(i)};
                    pos(2*i-1).x1 = x1;
                    pos(2*i-1).y1 = bb(p(i),2);
                    pos(2*i-1).x2 = x2;
                    pos(2*i-1).y2 = bb(p(i),4);
                    pos(2*i-1).flip = false;
                    pos(2*i-1).trunc = trunc(p(i));
                    
                    x1 = w(p(i)) - bb(p(i),3) + 1;
                    x2 = w(p(i)) - bb(p(i),1) + 1;                    
                    pos(2*i-0).im = Ipaths{p(i)};
                    pos(2*i-0).x1 = x1;
                    pos(2*i-0).y1 = bb(p(i),2);
                    pos(2*i-0).x2 = x2;
                    pos(2*i-0).y2 = bb(p(i),4);
                    pos(2*i-0).flip = true;
                    pos(2*i-0).trunc = trunc(p(i));
                end
            else
                p = class_ids == id;
                box = bb(p,:);
                pos = struct('im', Ipaths(p), 'x1', {box(:,1)}, 'y1', {box(:,2)}, 'x2', {box(:,3)}, 'y2', {box(:,4)}, 'flip', false, 'trunc', {trunc(:)});
            end
            
            n = class_ids ~= id;
            neg = struct('im', Ipaths(n), 'flip', false);            
        end
        %------------------------------------------------------------------
        function models = train_model_parallel(common, index)
            tid = task_open();

            n_index = length(index);
            models = cell(n_index, 1);
            
            for k = 1:n_index
                models{k} = LSVM.train_model(common.Ipaths, common.names{index(k)}, common.note, common.class_ids, common.n_compo, common.n_parts, index(k));
                task_progress(tid, k/n_index);
            end
            
            task_close(tid);
        end

        %------------------------------------------------------------------
        function model = train_model(Ipaths, name, note, class_ids, n_compo, n_parts, i)
            globals;
            try
              load([cachedir name '_final']);
            catch ME
                [pos, neg] = LSVM.make_examples(Ipaths, true, class_ids, i);
                if n_compo>length(pos)
                    n_compo = length(pos);
                end
                
                % split data by aspect ratio into n groups
                spos = split(name, pos, n_compo);

                cachesize = 24000;
                maxneg = min(length(neg), 200);

                % train root filters using warped positives & random negatives
                try
                  load(fullfile([cachedir name '_lrsplit1']));
                catch
                  initrand();
                  for i = 1:n_compo
                    % split data into two groups: left vs. right facing instances
                    models{i} = initmodel(name, spos{i}, note, 'N');
                    inds = lrsplit(models{i}, spos{i}, i);
                    models{i} = train(name, models{i}, spos{i}(inds), neg, i, 1, 1, 1, ...
                                      cachesize, true, 0.7, false, ['lrsplit1_' num2str(i)]);
                  end
                  save([cachedir name '_lrsplit1'], 'models');
                end

                % train root left vs. right facing root filters using latent detections
                % and hard negatives
                try
                  load([cachedir name '_lrsplit2']);
                catch
                  initrand();
                  for i = 1:n_compo
                    models{i} = lrmodel(models{i});
                    models{i} = train(name, models{i}, spos{i}, neg(1:maxneg), 0, 0, 4, 3, ...
                                      cachesize, true, 0.7, false, ['lrsplit2_' num2str(i)]);
                  end
                  save([cachedir name '_lrsplit2'], 'models');
                end

                % merge models and train using latent detections & hard negatives
                try 
                  load([cachedir name '_mix']);
                catch
                  initrand();
                  model = mergemodels(models);
                  model = train(name, model, pos, neg(1:maxneg), 0, 0, 1, 5, ...
                                cachesize, true, 0.7, false, 'mix');
                  save([cachedir name '_mix'], 'model');
                end

                % add parts and update models using latent detections & hard negatives.
                try 
                  load([cachedir name '_parts']);
                catch
                  initrand();
                  for i = 1:2:2*n_compo
                    model = model_addparts(model, model.start, i, i, n_parts, [6 6]);
                  end
                  model = train(name, model, pos, neg(1:maxneg), 0, 0, 8, 10, ...
                                cachesize, true, 0.7, false, 'parts_1');
                  model = train(name, model, pos, neg, 0, 0, 1, 5, ...
                                cachesize, true, 0.7, true, 'parts_2');
                  save([cachedir name '_parts'], 'model');
                end

                save([cachedir name '_final'], 'model');
            end
        end
        
        %------------------------------------------------------------------
        function scores = classify_parallel(common, models)
            tid = task_open();
                        
            n_img = length(common.Ipaths);
            n_classes = length(models);
            scores = ones(n_img,n_classes)*(-Inf);
            
            for i = 1:n_img
                im = imread(common.Ipaths{i});                
                [bb_not_cropped person_box] = get_bb_info(common.Ipaths{i});
                person_box = person_box(2:end);                
                
                for j = 1:n_classes
                    [dets, boxes] = imgdetect(im, models{j}, -Inf); %models{j}.thresh);
                    if ~isempty(boxes)
                        boxes = reduceboxes(models{j}, boxes);
                        [dets boxes] = clipboxes(im, dets, boxes);

                        overlap = inter_box(person_box, dets(:, 1:4));
                        I = overlap > common.overlap_th;
                        boxes = boxes(I,end);
                        if ~isempty(boxes)
                            scores(i,j) = max(boxes);
                        end
                    end
                end            
                task_progress(tid, i/n_img);
            end    
            
            scores = scores';
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function box = detect_parallel(im, models)
            tid = task_open();
            
            n_models = size(models,1);
            box = cell(n_models, 2);
            
            for i = 1:n_models
                b = detect(im, models{i}, -Inf);
                if ~isempty(b)
                    [m I] = max(b(:,end));
                    box{i,1} = b(I,:);
                    box{i,2} = m;
                else
                    box{i,1} = [];
                    box{i,2} = -Inf; 
                end
            end       
            task_close(tid);
        end               
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = LSVM(n_compo, n_parts, overlap_th)
            if nargin < 3
                overlap_th = 0.7;
            end    
            
            obj = obj@ClassifierAPI();
            obj.n_components = n_compo;
            obj.n_parts = n_parts;
            obj.overlap_th = overlap_th;
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function [cv_res cv_dev] = learn(obj, root)
            global TEMP_DIR HASH_PATH USE_PARALLEL;
            [Ipaths labels] = get_labeled_files(root, 'Loading training set...\n');
            [class_ids names] = names2ids(labels);
            obj.class_names = names;
            
            n_classes = length(obj.class_names);
            names = cell(n_classes,1);
            for i = 1:n_classes
                names{i} = sprintf('%s_%s_%d_%d', HASH_PATH, obj.class_names{i}, obj.n_components, obj.n_parts);
            end
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, obj.toFileName()));
            
            if exist(file, 'file') == 2
                load(file, 'lsvm_models');                
                obj.models = lsvm_models;
                write_log(sprintf('Classifier loaded from cache: %s.\n', file));
            else
                if USE_PARALLEL && 0
                    common = struct('Ipaths', [], 'names', [], 'note', obj.toFileName(), 'class_ids', class_ids, 'n_compo', obj.n_components, 'n_parts', obj.n_parts);
                    common.Ipaths = Ipaths;
                    common.names = names;
                    lsvm_models = run_in_parallel('LSVM.train_model_parallel', common, (1:n_classes)', [], 0);
                else
                    lsvm_models = cell(n_classes, 1);
                    for k = 1:n_classes
                        lsvm_models{k} = LSVM.train_model(Ipaths, names{k}, obj.toFileName(), class_ids, obj.n_components, obj.n_parts, k);
                    end
                end
                save(file, 'lsvm_models');
                obj.models = lsvm_models;
            end
                
            cv_res = [];
            cv_dev = [];
        end
        
        %------------------------------------------------------------------
        % Classify the testing pictures
        function [Ipaths classes correct_label assigned_label scores] = classify(obj, Ipaths, correct_label)
            global USE_PARALLEL;
            
            classes = obj.class_names;
            n_classes = size(classes, 1);
            
            if nargin < 3
                [Ipaths l] = get_labeled_files(Ipaths, 'Loading testing set...\n');
                correct_label = names2ids(l, classes);    
            end
            n_img = length(Ipaths);
                    
            pg = ProgressBar('Classifying', 'Computing bounding boxes...');
             
            if USE_PARALLEL
                common = struct('Ipaths', [], 'overlap_th', obj.overlap_th);
                common.Ipaths = Ipaths;
                scores = run_in_parallel('LSVM.classify_parallel', common, obj.models, [], 0, pg, 0, 1)';
            else
                scores = ones(n_img,n_classes)*(-Inf); 
                for i = 1:n_img
                    im = imread(Ipaths{i});
                    [bb_not_cropped person_box] = get_bb_info(Ipaths{i});
                    person_box = person_box(2:end);   
                    
                    for j = 1:n_classes
                        [dets, boxes] = imgdetect(im, obj.models{j}, -Inf); %models{j}.thresh);
                        if ~isempty(boxes)
                            boxes = reduceboxes(obj.models{j}, boxes);
                            [dets boxes] = clipboxes(im, dets, boxes);
                          
                            overlap = inter_box(person_box, dets(:, 1:4));
                            I = overlap > obj.overlap_th;
                            boxes = boxes(I,end);
                            if ~isempty(boxes)
                                scores(i,j) = max(boxes);
                            end
                        end
                    end
                    pg.progress(i/n_img);
                end    
            end

            assigned_label = zeros(n_img,1); 
            for i = 1:n_img
                [m, j] = max(scores(i,:));
                assigned_label(i) = j;
            end
            
            pg.close();
        end
        
        %------------------------------------------------------------------
        % Classify the given picture
        function boxes = classify_and_get_boxes(obj, Ipath, visu)
            global USE_PARALLEL;
            
            if nargin < 3
                visu = 0;
            end
            classes = obj.class_names;
            n_classes = size(classes, 1);
            
            scores = ones(1,n_classes)*(-Inf);
            box = cell(1,n_classes);
            
            im = imread(Ipath);
            if USE_PARALLEL
                box = run_in_parallel('LSVM.detect_parallel', im, obj.models, 0, 0);
                [m, i] = max([box{:,2}]);
                boxes = box{i,1};
            else
                for i = 1:n_classes
                    b = detect(im, obj.models{i}, -Inf);
                    if ~isempty(b)
                        [m I] = max(b(:,end));
                        scores(i) = m;
                        box{i} = b(I,:);
                    else
                        box{i} = [];
                    end
                end            

                [m, i] = max(scores);
                boxes = box{i};
            end
            
            fprintf('Image assigned to %s\n', classes{i});           
            
            if visu
                showboxes(im, boxes);
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('LSVM (%d components, %d parts, BB overlap = %s)', obj.n_components, obj.n_parts, num2str(obj.overlap_th));
        end
        function str = toFileName(obj)
            str = sprintf('LSVM[%d-%d-%s]', obj.n_components, obj.n_parts, num2str(obj.overlap_th));
        end
        function str = toName(obj)
            str = sprintf('LSVM(%d-%d)', obj.n_components, obj.n_parts);
        end
        function obj = save_to_temp(obj)
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.toFileName()));
            if ~existe(file,'file') == 2                
                lsvm_models = obj.models;
                save(file, 'lsvm_models');
            end
        end
    end    
end
