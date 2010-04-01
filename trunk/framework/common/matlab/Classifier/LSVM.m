classdef LSVM < ClassifierAPI
    % Latent SVM
    
    properties
        class_names
        lsvm
    end
    
    methods (Access = protected)
        function [pos, neg] = make_examples(obj, Ipaths, class_ids, id)
            n_img = numel(Ipaths);
            
            w = cell(n_img, 1);
            h = cell(n_img, 1);
            O = cell(n_img, 1);
            for i=1:n_img
                info = imfinfo(Ipaths{i});
                w{i} = info.Width;
                h{i} = info.Height;
                O{i} = 0;
            end
            
            p = class_ids == id;
            pos = struct('im', Ipaths(p), 'x1', O(p), 'y1', O(p), 'x2', w(p), 'y2', h(p));
            n = class_ids ~= id;
            neg = struct('im', Ipaths(n), 'x1', O(n), 'y1', O(n), 'x2', w(n), 'y2', h(n));            
        end
        
        function model = train_model(obj, Ipaths, class_ids, name, i, n)
            global TEMP_DIR HASH_PATH;
            try
              load(fullfile(TEMP_DIR, sprintf('%s_%s_final', HASH_PATH, name)));
            catch  
                [pos, neg] = make_examples(obj, Ipaths, class_ids, i);

                if n>length(pos)
                    n = length(pos);
                end
                n_neg = min(length(neg), 200);

                spos = split(pos, n);
                % train root filters using warped positives & random negatives
                try
                  load(fullfile(TEMP_DIR, sprintf('%s_%s_random', HASH_PATH, name)));
                catch
                  models = cell(n,1);
                  for i=1:n
                    models{i} = initmodel(spos{i});
                    models{i} = train(name, models{i}, spos{i}, neg, 1, 1, 1, 1, 2^28);
                  end
                  save(fullfile(TEMP_DIR, sprintf('%s_%s_random', HASH_PATH, name)), 'models');
                end

                % merge models and train using latent detections & hard negatives
                try 
                  load(fullfile(TEMP_DIR, sprintf('%s_%s_hard', HASH_PATH, name)));
                catch
                  model = mergemodels(models);
                  model = train(name, model, pos, neg(1:n_neg), 0, 0, 2, 2, 2^28, true, 0.7);
                  save(fullfile(TEMP_DIR, sprintf('%s_%s_hard', HASH_PATH, name)), 'model');
                end

                % add parts and update models using latent detections & hard negatives.
                try 
                  load(fullfile(TEMP_DIR, sprintf('%s_%s_parts', HASH_PATH, name)));
                catch
                  for i=1:n
                    model = addparts(model, i, 6);
                  end 
                  % use more data mining iterations in the beginning
                  model = train(name, model, pos, neg(1:n_neg), 0, 0, 1, 4, 2^30, true, 0.7);
                  model = train(name, model, pos, neg(1:n_neg), 0, 0, 6, 2, 2^30, true, 0.7, true);
                  save(fullfile(TEMP_DIR, sprintf('%s_%s_parts', HASH_PATH, name)), 'model');
                end

                % update models using full set of negatives.
                try 
                  load(fullfile(TEMP_DIR, sprintf('%s_%s_mine', HASH_PATH, name)));
                catch
                  model = train(name, model, pos, neg, 0, 0, 1, 3, 2^30, true, 0.7, true, ...
                                0.003*model.numcomponents, 2);
                  save(fullfile(TEMP_DIR, sprintf('%s_%s_mine', HASH_PATH, name)), 'model');
                end

                % train bounding box prediction
                model = trainbox(name, model, pos, 0.7);
                save(fullfile(TEMP_DIR, sprintf('%s_%s_final', HASH_PATH, name)), 'model');
            end
        end
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = LSVM()
            obj = obj@ClassifierAPI([]);
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function cross_validation = learn(obj, root)
            global TEMP_DIR HASH_PATH;
            [Ipaths labels] = get_labeled_files(root, 'Loading training set...\n');
            [class_ids names] = names2ids(labels);
            obj.class_names = names;
            
            n_classes = length(obj.class_names);
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, obj.toFileName()));
            
            if exist(file, 'file') == 2
                load(file, 'models');                
                obj.models = models;
                write_log(sprintf('Classifier loaded from cache: %s.\n', file));
            else
                models = cell(n_classes, 1); 
                for i = 1:n_classes
                    models{i} = obj.train_model(Ipaths, class_ids, obj.class_names{i}, i, 3);
                end
                save(file, 'models');
                obj.models = models;
            end
                
            cross_validation = [];
        end
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        function [Ipaths classes correct_label assigned_label score] = classify(obj, Ipaths, correct_label)
            
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = 'LSVM';
        end
        function str = toFileName(obj)
            str = 'LSVM';
        end
        function str = toName(obj)
            str = 'LSVM';
        end
    end
    
end

