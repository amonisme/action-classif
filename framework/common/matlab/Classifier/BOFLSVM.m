classdef BOFLSVM < ClassifierAPI
    % Latent SVM
    
    properties
        models
        detector
        descriptor
        kmeans
        K             % BOF size
        n_components  % number of component in the mixture model  
        n_parts       % number of parts
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function [pos, neg, centers] = make_examples(detector, descriptor, kmeans, Ipaths, flippedpos, class_ids, map_ids, id)
            global TEMP_DIR HASH_PATH;
            
            n_img = numel(Ipaths);
            
            w = zeros(n_img,1);
            bb = zeros(n_img, 4);
            trunc = zeros(n_img,1);
                        
            klib = kmeans.get_lib();
            detect = detector.toFileName();
            descrp = descriptor.toFileName();
            file = sprintf('Kmeans[%s-%d-%d-%s-%s]', klib, kmeans.K, 0, descrp, detect);
            
            feat = SignatureAPI.compute_features(detector, Ipaths);
            descr = SignatureAPI.compute_descriptors(detector, descriptor, Ipaths, feat);
            kmeans.prepare_kmeans(descr);
            centers = kmeans.do_kmeans(fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,file)));
            
            for i=1:n_img
                [bb_not_cropped bbox width] = get_bb_info(Ipaths{i});
                w(i) = width;
                trunc(i) = bbox(1);
                bb(i,:) = bbox(2:end);
                
                d = dist2(centers, descr{i});
                m = (d == repmat(min(d), size(d,1), 1));
                n_descr = size(descr{i}, 1);
                for j=1:n_descr
                    a = find(m(:,j), 1);
                    % X Y Scale Angle Type
                    feat{i}(j,5) = a;
                end                
            end
            trunc = logical(trunc);

            if flippedpos
                p = find(class_ids == id);
                n_pos = length(p);
                pos = struct('im', cell(n_pos*2,1), 'flip', false, 'x1', 0, 'y1', 0, 'x2', 0, 'y2', 0, 'feat', []);
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
                    pos(2*i-1).feat = feat{p(i)};                    
                    
                    x1 = w(p(i)) - bb(p(i),3) + 1;
                    x2 = w(p(i)) - bb(p(i),1) + 1;                    
                    pos(2*i-0).im = Ipaths{p(i)};
                    pos(2*i-0).x1 = x1;
                    pos(2*i-0).y1 = bb(p(i),2);
                    pos(2*i-0).x2 = x2;
                    pos(2*i-0).y2 = bb(p(i),4);
                    pos(2*i-0).flip = true;
                    pos(2*i-0).trunc = trunc(p(i));
                    pos(2*i-0).feat = feat{p(i)};   
                end
            else
                p = class_ids == id;
                box = bb(p,:);
                pos = struct('im', Ipaths(p), 'x1', {box(:,1)}, 'y1', {box(:,2)}, 'x2', {box(:,3)}, 'y2', {box(:,4)}, 'flip', false, 'trunc', {trunc(:)}, 'feat', feat(p));
            end
            
            if ~isempty(map_ids) % if empty, it is identity
                same_class = find(map_ids == map_ids(id));
                n = ones(n_img,1);
                for i=1:length(same_class)
                    n = n & class_ids ~= same_class(i);
                end
            else
                n = class_ids ~= id;
            end
            neg = struct('im', Ipaths(n), 'flip', false, 'feat', feat(n));  
        end

        %------------------------------------------------------------------
        function models = train_model_parallel(common, index)
            tid = task_open();

            n_index = length(index);
            models = cell(n_index, 1);
            
            for k = 1:n_index
                models{k} = BOFLSVM.train_model(common.detector, common.descriptor, common.kmeans, common.Ipaths, common.names{index(k)}, common.note, common.class_ids, common.map_ids, common.n_compo, common.n_parts, index(k));
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
                models{k} = initmodel(common.name, common.spos{i}, common.note, common.centers, 'N');
                inds = lrsplit(models{k}, common.spos{i}, i);
                models{k} = train(common.name, models{k}, common.spos{i}(inds), common.neg, i, 1, 1, 1, ...
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
                models{k} = train(common.name, models{k}, common.spos{i}, common.neg(1:common.maxneg), 0, 0, 4, 3, ...                    
                                  common.cachesize, true, 0.7, false, ['lrsplit2_' num2str(i)]);
            end
                          
            task_close(tid);
        end        

        %------------------------------------------------------------------
        function model = train_model(detector, descriptor, kmeans, Ipaths, name, note, class_ids, map_ids, n_compo, n_parts, i)            
            globals;
            try
              load([cachedir name '_final']);
            catch ME
                try
                  load(fullfile([cachedir name '_examples']));
                catch  
                  [pos, neg, centers] = BOFLSVM.make_examples(detector, descriptor, kmeans, Ipaths, true, class_ids, map_ids, i);
                  save([cachedir name '_examples'], 'pos', 'neg', 'centers');
                end
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
                      common = struct('name', name, 'spos', [], 'neg', neg, 'note', note, 'centers', centers, 'cachesize', cachesize);
                      common.spos = spos;
                      models = run_in_parallel('BOFLSVM.lrsplit1_parallel', common, (1:n_compo)', 0, 0);
                  else
                      initrand(); 
                      for i = 1:n_compo
                        % split data into two groups: left vs. right facing instances                    
                        models{i} = initmodel(name, spos{i}, note, centers, 'N');
                        inds = lrsplit(models{i}, spos{i}, i);                                             
                        models{i} = train(name, models{i}, spos{i}(inds), neg, i, 1, 1, 1, ...
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
                      models = run_in_parallel('BOFLSVM.lrsplit2_parallel', common, (1:n_compo)', 0, 0);
                  else
                      initrand();
                      for i = 1:n_compo
                        models{i} = lrmodel(models{i});                    
                        %models{i} = train(name, models{i}, spos{i}, neg(1:maxneg), 0, 0, 1, 1, ...
                        models{i} = train(name, models{i}, spos{i}, neg(1:maxneg), 0, 0, 4, 3, ...                                            
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
                  %model = train(name, model, pos, neg(1:maxneg), 0, 0, 1, 1, ...    
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
                  
                  %model = train(name, model, pos, neg(1:maxneg), 0, 0, 1, 1, ...                                            
                  model = train(name, model, pos, neg(1:maxneg), 0, 0, 8, 10, ...
                                cachesize, true, 0.7, false, 'parts_1');
                  
                  %model = train(name, model, pos, neg, 0, 0, 1, 1, ...
                  model = train(name, model, pos, neg, 0, 0, 1, 5, ...
                                cachesize, true, 0.7, true, 'parts_2');
                  save([cachedir name '_parts'], 'model');
                end
                
                save([cachedir name '_final'], 'model');
            end
        end
        
        %------------------------------------------------------------------
        function scores = classify_img_parallel(common, Ipaths)
            tid = task_open();
                        
            scores = BOFLSVM.classify_img(common.model, Ipaths, common.overlaps);
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function scores = classify_img(model, Ipaths, overlaps)
            n_img = length(Ipaths);
            n_overlaps = length(overlaps);
            scores = ones(1,n_img,n_overlaps)*(-Inf);
            
            for i = 1:n_img
                im = imread(Ipaths{i});                
                [bb_not_cropped person_box] = get_bb_info(Ipaths{i});
                person_box = person_box(2:end);                
                
                [dets, boxes] = my_imgdetect(Ipaths{i}, model, -Inf); %models{j}.thresh);
                if ~isempty(boxes)
                    boxes = reduceboxes(model, boxes);
                    [dets boxes] = clipboxes(im, dets, boxes);

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
        function obj = BOFLSVM(K, n_compo, n_parts)
            if nargin < 1
                K = 1;
            end
            if nargin < 2
                n_compo = 3;
            end            
            if nargin < 3
                n_parts = 8;
            end            
            obj = obj@ClassifierAPI();
            obj.K = K;
            obj.n_components = n_compo;
            obj.n_parts = n_parts;
            obj.detector = MS_Dense(4,1.3);
            obj.descriptor = SIFT(L2Trunc);
            obj.kmeans = Kmeans(K, 'c', 200);            
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function [cv_prec cv_dev_prec cv_acc cv_dev_acc] = learn(obj, root)
            global TEMP_DIR HASH_PATH USE_PARALLEL;
            [Ipaths ids map c_names subc_names] = get_labeled_files(root, 'Loading training set...\n');            
            obj.store_names(c_names, subc_names, map);           
            
            n_classes = length(obj.subclasses_names);
            names = cell(n_classes,1);
            for i = 1:n_classes
                names{i} = sprintf('%s_%s_%d_%d', HASH_PATH, obj.subclasses_names{i}, obj.n_components, obj.n_parts);
            end
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, obj.toFileName()));
            
            if exist(file, 'file') == 2
                load(file, 'lsvm_models');                
                obj.models = lsvm_models;
                write_log(sprintf('Classifier loaded from cache: %s.\n', file));
            else
                if USE_PARALLEL
                    common = struct('Ipaths', [], ...
                                    'names', [], ...
                                    'note', obj.toFileName(), ...
                                    'class_ids', ids, ...
                                    'map_ids', map, ...
                                    'n_compo', obj.n_components, ...
                                    'n_parts', obj.n_parts, ...
                                    'detector', obj.detector, ...
                                    'descriptor', obj.descriptor, ...
                                    'kmeans', obj.kmeans);
                    common.Ipaths = Ipaths;
                    common.names = names;
                    lsvm_models = run_in_parallel('BOFLSVM.train_model_parallel', common, (1:n_classes)', 0, 0);
                else
                    lsvm_models = cell(n_classes, 1);
                    for k = 1:n_classes
                        lsvm_models{k} = BOFLSVM.train_model(obj.detector, obj.descriptor, obj.kmeans, Ipaths, names{k}, obj.toFileName(), ids, map, obj.n_components, obj.n_parts, k);
                    end
                end
                
                for k = 1:n_classes
                    lsvm_models{k}.detector = obj.detector;
                    lsvm_models{k}.descriptor = obj.descriptor;
                    lsvm_models{k}.kmeans = obj.kmeans;
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
        function [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = classify(obj, Ipaths, correct_label)            
            global USE_PARALLEL TEMP_DIR HASH_PATH;
            
            classes = obj.classes_names;
            subclasses = obj.subclasses_names;
            map_sub2sup = obj.map_sub2sup;   
                      
            if nargin < 3
                [Ipaths ids] = get_labeled_files(Ipaths, 'Loading testing set...\n');            
                correct_label = ids;
            end

            n_img = length(Ipaths);
                    
            pg = ProgressBar('Classifying', 'Computing bounding boxes...');
                     
            overlaps = 0:0.1:0.9;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s_saved_scores.mat', HASH_PATH, obj.toFileName()));
            
            if exist(file, 'file') == 2
                load(file, 'scores');
            else           
                if USE_PARALLEL
                    n_classes = length(obj.models);
                    scores = cell(1,n_classes);
                    for i = 1:n_classes
                        common = struct('model', obj.models{i}, 'overlaps', overlaps);
                        scores{i} = run_in_parallel('BOFLSVM.classify_img_parallel', common, Ipaths, [], 0, pg, (i-1)/n_classes, 1/n_classes);
                        scores{i} = obj.classify_img(obj.models{i}, Ipaths, overlaps);
                    end
                    scores = cat(1, scores{:});                   
                else            
                    n_classes = length(obj.models);
                    scores = cell(1,n_classes);
                    for i = 1:n_classes
                        scores{i} = obj.classify_img(obj.models{i}, Ipaths, overlaps);
                        pg.progress(i/n_classes);
                    end
                    scores = cat(1, scores{:});
                end
                save(file, 'scores');
            end            
            scores = scores(:,:,6);  % 0.5 overlap
            scores = scores';    

            assigned_label = zeros(n_img,1); 
            for i = 1:n_img
                [m, j] = max(scores(i,:));
                assigned_label(i) = j;
            end
            
            pg.close();
        end
        
        %------------------------------------------------------------------
        % Classify the given picture
        function [dets parts] = get_boxes(obj, model_id, Ipath, visu)
            if nargin < 4
                visu = 0;
            end
            
            default_overlap = 0.5;
                
            im = imread(Ipath);
            [bb_not_cropped person_box] = get_bb_info(Ipath);
            person_box = person_box(2:end);  

            [dets, boxes] = my_imgdetect(Ipath, obj.models{model_id}, -Inf);
            if ~isempty(boxes)
                boxes = reduceboxes(obj.models{model_id}, boxes);
                [dets boxes] = clipboxes(im, dets, boxes);

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
                showboxes(im, parts);
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('BOFLSVM (%d words, %d components, %d parts)', obj.K, obj.n_components, obj.n_parts);
        end
        function str = toFileName(obj)
            str = sprintf('BOFLSVM[%d-%d-%d]', obj.K, obj.n_components, obj.n_parts);
        end
        function str = toName(obj)
            str = sprintf('BOFLSVM(%d-%d-%d)', obj.K, obj.n_components, obj.n_parts);
        end
    end    
end
