classdef PoseletLSVM < ClassifierAPI
    % Latent SVM
    
    properties
        models
        n_components  % number of component in the mixture model  
        n_parts       % number of parts
    end
    
    methods (Static)              
        %------------------------------------------------------------------
        function [pos, neg] = make_examples(images, flippedpos, map_ids, id)
            n_img = length(images);
            
            w = zeros(n_img,1);
            bb = zeros(n_img, 4);
            trunc = zeros(n_img,1);            
            for i=1:n_img
                w(i) = images(i).size(1);
                trunc(i) = images(i).truncated;
                bb(i,:) = images(i).bndbox;
            end
            trunc = logical(trunc);
            
            do_action = cat(1,images(:).actions);
            if flippedpos
                p = find(do_action(:,id));
                n_pos = length(p);
                pos = struct('im', cell(n_pos*2,1), 'flip', false, 'x1', 0, 'y1', 0, 'x2', 0, 'y2', 0);
                for i = 1:n_pos 
                    x1 = images(p(i)).bndbox(1);
                    x2 = images(p(i)).bndbox(3);
                    pos(2*i-1).im = images(p(i)).path;
                    pos(2*i-1).x1 = x1;
                    pos(2*i-1).y1 = images(p(i)).bndbox(2);
                    pos(2*i-1).x2 = x2;
                    pos(2*i-1).y2 = images(p(i)).bndbox(4);
                    pos(2*i-1).flip = false;
                    pos(2*i-1).trunc = images(p(i)).truncated;
                    
                    w = images(p(i)).size(1);
                    x1 = w - bb(p(i),3) + 1;
                    x2 = w - bb(p(i),1) + 1;                    
                    pos(2*i-0).im = images(p(i)).path;
                    pos(2*i-0).x1 = x1;
                    pos(2*i-0).y1 = images(p(i)).bndbox(2);
                    pos(2*i-0).x2 = x2;
                    pos(2*i-0).y2 = images(p(i)).bndbox(4);
                    pos(2*i-0).flip = true;
                    pos(2*i-0).trunc = images(p(i)).truncated;
                end
            else
                p = do_action(:,id);
                box = bb(p,:);
                pos = struct('im', {images(p).path}, 'x1', {box(:,1)}, 'y1', {box(:,2)}, 'x2', {box(:,3)}, 'y2', {box(:,4)}, 'flip', false, 'trunc', {trunc(:)});
            end
            
            if ~isempty(map_ids) % if empty, it is identity
                n = sum(do_action(:, map_ids == map_ids(id) ),2) == 0;                
            else
                n = ~do_action(:,id);
            end
            neg = struct('im', {images(n).path}, 'flip', false);  
        end
        %------------------------------------------------------------------
        function models = train_model_parallel(common, index)
            tid = task_open();

            n_index = length(index);
            models = cell(n_index, 1);
            
            for k = 1:n_index
                models{k} = PoseletLSVM.train_model(common.images, common.names{index(k)}, common.note, common.map_ids, common.n_compo, common.n_parts, index(k));
                task_progress(tid, k/n_index);
            end
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function models = lrsplit1_parallel(common, I)
            tid = task_open();
            
            initrand();       
            % split data into two groups: left vs. right facing instances
            for k = 1:length(I)
                i = I(k);
                models{k} = poselet_initmodel(common.name, common.spos{i}, common.note, 'N');
                inds = poselet_lrsplit(models{k}, common.spos{i}, i);
                models{k} = poselet_train(common.name, models{k}, common.spos{i}(inds), common.neg, i, 1, 1, 1, ...
                                  common.cachesize, true, 0.7, false, ['lrsplit1_' num2str(i)]);
            end
                          
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function models = lrsplit2_parallel(common, I)
            tid = task_open();
            
            initrand();
            for k = 1:length(I)
                i = I(k);
                models{k} = lrmodel(common.models{i});                    
                models{k} = poselet_train(common.name, models{k}, common.spos{i}, common.neg(1:common.maxneg), 0, 0, 4, 3, ...                    
                                  common.cachesize, true, 0.7, false, ['lrsplit2_' num2str(i)]);
            end
                          
            task_close(tid);
        end        

        %------------------------------------------------------------------
        function model = train_model(images, name, note, map_ids, n_compo, n_parts, i)
            globals;
            try
              load([cachedir name '_final']);
            catch ME
                file_ex = fullfile(cachedir, [name '_examples_' descriptor.toFileName() '_' detector.toFileName()]);
                try                    
                  load(file_ex);
                  fprintf('Examples loaded from: %s\n', file_ex);
                catch  
                  [pos, neg] = PoseletLSVM.make_examples(images, true, map_ids, i);
                  save(file_ex, 'pos', 'neg');
                end                
                [pos, neg] = PoseletLSVM.make_examples(images, true, map_ids, i);
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
                  if 0
                      common = struct('name', name, 'spos', [], 'neg', neg, 'note', note, 'cachesize', cachesize);
                      common.spos = spos;
                      models = run_in_parallel('PoseletLSVM.lrsplit1_parallel', common, (1:n_compo)', 0, 0);
                  else
                      initrand(); 
                      for i = 1:n_compo
                        % split data into two groups: left vs. right facing instances                    
                        models{i} = poselet_initmodel(name, spos{i}, note, 'N');
                        inds = poselet_lrsplit(models{i}, spos{i}, i);
                        models{i} = poselet_train(name, models{i}, spos{i}(inds), neg, i, 1, 1, 1, ...
                                          cachesize, true, 0.7, false, ['lrsplit1_' num2str(i)]);
                      end
                  end
                  save([cachedir name '_lrsplit1'], 'models');
                end

                % train root left vs. right facing root filters using latent detections
                % and hard negatives
                try
                  load([cachedir name '_lrsplit2']);
                catch
                  if 0
                      common = struct('name', name, 'spos', [], 'neg', neg, 'maxneg', maxneg, 'models', [], 'cachesize', cachesize);
                      common.spos = spos;
                      common.models = models;
                      models = run_in_parallel('PoseletLSVM.lrsplit2_parallel', common, (1:n_compo)', 0, 0);
                  else
                      initrand();
                      for i = 1:n_compo
                        models{i} = lrmodel(models{i});                    
                        models{i} = poselet_train(name, models{i}, spos{i}, neg(1:maxneg), 0, 0, 4, 3, ...                    
                                          cachesize, true, 0.7, false, ['lrsplit2_' num2str(i)]);
                      end
                  end
                  save([cachedir name '_lrsplit2'], 'models');
                end

                % merge models and train using latent detections & hard negatives
                try 
                  load([cachedir name '_mix']);
                catch
                  initrand();
                  model = mergemodels(models);
                  model = poselet_train(name, model, pos, neg(1:maxneg), 0, 0, 1, 5, ...
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
                  model = poselet_train(name, model, pos, neg(1:maxneg), 0, 0, 8, 10, ...                      
                                cachesize, true, 0.7, false, 'parts_1');
                  model = poselet_train(name, model, pos, neg, 0, 0, 1, 5, ...
                                cachesize, true, 0.7, true, 'parts_2');
                  save([cachedir name '_parts'], 'model');
                end

                save([cachedir name '_final'], 'model');
            end
        end
        
        %------------------------------------------------------------------
        function scores = classify_parallel(common, models)
            tid = task_open();
                        
            n_classes = length(models);
            scores = cell(1,n_classes);
            
            for i = 1:n_classes
                scores{i} = PoseletLSVM.classify_img(models{i}, common.images, common.overlaps);
                task_progress(tid, i/n_classes);
            end
            scores = cat(1, scores{:});
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function scores = classify_img(model, images, overlaps)
            n_img = length(images);
            n_overlaps = length(overlaps);
            scores = ones(1,n_img,n_overlaps)*(-Inf);
            
            for i = 1:n_img 
                person_box = images(i).bndbox;                
                
                [dets, boxes] = poselet_imgdetect(imread(images(i).path), model, -Inf);
                if ~isempty(boxes)
                    boxes = reduceboxes(model, boxes);
                    [dets boxes] = my_clipboxes(images(i).size(1), images(i).size(2), dets, boxes);

                    overlap = inter_box(person_box, dets(:, 1:4));
                    for k = 1:n_overlaps
                        I = overlap >= overlaps(k);
                        if ~isempty(find(I,1))
                            scores(1,i,k) = max(boxes(I,end));
                        end
                    end
                end        
            end    
        end    
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = PoseletLSVM(n_compo, n_parts)
            if nargin < 1
                n_compo = 3;
            end            
            if nargin < 2
                n_parts = 8;
            end            
            obj = obj@ClassifierAPI();
            obj.n_components = n_compo;
            obj.n_parts = n_parts;
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function [cv_prec cv_dev_prec cv_acc cv_dev_acc] = learn(obj, root)
            global TEMP_DIR HASH_PATH USE_PARALLEL;
            [images map c_names subc_names] = get_labeled_files(root, 'Loading training set...\n');            
            obj.store_names(c_names, subc_names, map);           
            
            n_classes = length(obj.subclasses_names);
            names = cell(n_classes,1);
            for i = 1:n_classes
                names{i} = sprintf('%s_%s_%s', HASH_PATH, obj.toFileName(), obj.subclasses_names{i});
            end
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, obj.toFileName()));
            
            if exist(file, 'file') == 2
                load(file, 'lsvm_models');                
                obj.models = lsvm_models;
                write_log(sprintf('Classifier loaded from cache: %s.\n', file));
            else
                if USE_PARALLEL
                    common = struct('images', images, 'names', [], 'note', obj.toFileName(), 'map_ids', map, 'n_compo', obj.n_components, 'n_parts', obj.n_parts);
                    common.names = names;
                    lsvm_models = run_in_parallel('PoseletLSVM.train_model_parallel', common, (1:n_classes)', 0, 0);
                else
                    lsvm_models = cell(n_classes, 1);
                    for k = 1:n_classes
                        lsvm_models{k} = PoseletLSVM.train_model(images, names{k}, obj.toFileName(), map, obj.n_components, obj.n_parts, k);
                    end
                end
                save(file, 'lsvm_models');
                obj.models = lsvm_models;
            end
                
            cv_prec = [];
            cv_dev_prec = [];
            cv_acc = [];
            cv_dev_acc = [];            
        end
        
        %------------------------------------------------------------------
        % Classify the testing pictures
        function [images classes subclasses map_sub2sup assigned_action scores] = classify(obj, root_images)            
            global USE_PARALLEL TEMP_DIR HASH_PATH;
            
            classes = obj.classes_names;
            subclasses = obj.subclasses_names;
            map_sub2sup = obj.map_sub2sup;  
            
            [images map_sub2sup subclasses subclasses] = get_labeled_files(root_images, 'Loading testing set...\n');      

            n_img = length(images);
                    
            pg = ProgressBar('Classifying', 'Computing bounding boxes...');
                     
            overlaps = 0:0.1:0.9;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s_saved_scores.mat', HASH_PATH, obj.toFileName()));
            
            if exist(file, 'file') == 2
                load(file, 'scores');
                fprintf('Scores loaded from: %s\n', file);
            else           
                if USE_PARALLEL 
                    common = struct('images', images, 'overlaps', overlaps);
                    scores = run_in_parallel('PoseletLSVM.classify_parallel', common, obj.models, [], 0, pg, 0, 1);
                else            
                    n_classes = length(obj.models);
                    scores = cell(1,n_classes);
                    for i = 1:n_classes
                        scores{i} = obj.classify_img(obj.models{i}, images, overlaps);
                        pg.progress(i/n_classes);
                    end
                    scores = cat(1, scores{:});
                end
                save(file, 'scores');
            end            
            scores = scores(:,:,6);  % 0.5 overlap
            scores = scores';    

            assigned_action = zeros(n_img,size(scores, 2));
            for i = 1:n_img
                [m, j] = max(scores(i,:));
                assigned_action(i, j) = 1;
            end
            
            pg.close();
        end
        
        %------------------------------------------------------------------
        % Classify the given picture
        function [dets parts] = get_boxes(obj, model_id, image, visu)
            if nargin < 4
                visu = 0;
            end
            
            default_overlap = 0.5;

            person_box = image.bndbox;

            [dets, boxes] = poselet_imgdetect(imread(image.path), obj.models{model_id}, -Inf);
            if ~isempty(boxes)
                boxes = reduceboxes(obj.models{model_id}, boxes);
                [dets boxes] = my_clipboxes(image.size(1), image.size(2), dets, boxes);

                I = inter_box(person_box, dets(:, 1:4)) > default_overlap;              
                if ~isempty(find(I,1))
                    dets(~I,end) = -Inf;
                    [m I] = max(dets(:,end));
                    dets = dets(I,:);
                    parts = boxes(I,:);
                else
                    dets = [];
                    parts = [];
                end                                              
            end
            
            if visu
                showboxes(imread(image.path), parts);
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('PoseletLSVM (%d components, %d parts)', obj.n_components, obj.n_parts);
        end
        function str = toFileName(obj)
            str = sprintf('PoseletLSVM[%d-%d]', obj.n_components, obj.n_parts);
        end
        function str = toName(obj)
            str = sprintf('PoseletLSVM(%d-%d)', obj.n_components, obj.n_parts);
        end
    end    
end
