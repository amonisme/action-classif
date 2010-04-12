classdef SVM < ClassifierAPI & CrossValidateAPI
   
    properties (SetAccess = protected, GetAccess = protected)
        C 	        % trade-off between training error and margin (if -1, then set to default [avg. x*x]^-1, set to [] for cross-validation)
        J	        % Cost-factor, by which training errors on positive examples outweight errors on negative examples (default 1)
        K           % K-fold cross-validation
        param_cv    % remember which parameterter was cross-validated
        kernel
        precomputed_dist_file
        svm
        OneVsOne
        class_names
        class_id
    end
        
    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if ~isfield(a, 'param_cv')
                obj.param_cv = [1];
            end
        end            
        %------------------------------------------------------------------
        function svm = learn_parallel(info, args)
            tid = task_open();
            
            n_models = size(args, 1);
            svm = cell(n_models, 1);
            for i=1:n_models
                svm{i} = info.kernel.learn(info.C, info.J, args(i).labels, args(i).sigs, info.file_precompute);
                task_progress(tid, i/n_models);
            end            
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function res = classify_ovo_parallel(info, args)
            tid = task_open();
            
            n_models = size(args,1);
            n_img = size(info.sigs,1);
            vote = zeros(n_img,info.n_classes);
            sc = zeros(n_img,info.n_classes);
            for k=1:n_models
                s = info.kernel.classify(args(k).svm, info.sigs, info.file_precompute);

                pos = s>=0;
                neg = s<0;

                vote(pos,args(k).i) = vote(pos,args(k).i) + 1;
                vote(neg,args(k).j) = vote(neg,args(k).j) + 1;                       

                sc(pos,args(k).i) = sc(pos,args(k).i) + s(pos);
                sc(neg,args(k).j) = sc(neg,args(k).j) - s(neg);                         
                task_progress(tid,k/n_models);
            end
            res = struct('vote', vote, 'sc', sc);
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function sc = classify_ova_parallel(info, svm)
            tid = task_open();
                     
            n_models = size(svm,1);    
            n_img = size(info.sigs,1);
            sc = zeros(n_models,n_img);   
            for k=1:n_models
                sc(k,:) = info.kernel.classify(svm{k}, info.sigs, info.file_precompute)';
                task_progress(tid,k/n_models);
            end
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function res = cross_validate_parallel(info, params)
            tid = task_open();
            global USE_PARALLEL;
            USE_PARALLEL = 0;
                      
            n_params = size(params, 1);
            res = zeros(n_params,1);
            for i=1:n_params
                info.obj.set_params(params(i,:));
                res(i) = info.obj.K_fold_cross_validate(info.train_sigs, info.class_id, info.folds, info.file);
                task_progress(tid,i/n_params);
            end           

            task_close(tid);
        end        
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SVM(kernel, signature, strat, C, J, K)
            if(nargin < 3)
                strat = 'OneVsAll';
            end
            if(nargin < 4)
                C = -1;
            end
            if(nargin < 5)
            	J = 1;
            end
            if(nargin < 6)
            	K = 5;
            end
            
            obj = obj@ClassifierAPI(signature);
	        obj.C = C;
            obj.J = J;
            obj.K = K;
            obj.kernel = kernel;
            
            obj.param_cv = [0];
            if isempty(C)
                obj.param_cv(1) = 1;
            end

            if(strcmpi(strat, 'onevsone'))
                obj.OneVsOne = 1;
            else
                if(strcmpi(strat, 'onevsall'))
                    obj.OneVsOne = 0;
                else
                    throw(MException('',['Unknown strategie for SVM: "' strat '".\nPossible values are: "OneVsAll" and "OneVsOne".\n']));
                end
            end
            
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root', eventually do a cross
        % validation
        function cv_res = learn(obj, root)
            [Ipaths labels] = get_labeled_files(root, 'Loading training set...\n');
            [class_ids names] = names2ids(labels);
            obj.class_names = names;
            obj.class_id = class_ids;
            obj.signature.learn(Ipaths); 
            
            global HASH_PATH TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.toFileName()));
            
            if exist(file,'file') == 2
                load(file,'svm', 'cv_res');
                obj.svm = svm;
                write_log(sprintf('Classifier loaded from cache: %s.\n', file));
            else           
                if obj.C == -1
                    obj.C = 1/mean(sum(obj.signature.train_sigs.*obj.signature.train_sigs,2));
                end
                
                % Precompute distance (eventually)
                obj.precomputed_dist_file = obj.kernel.precompute(obj.signature.train_sigs);                
                [best_params cv_res] = cross_validate(obj, obj.K);
                obj.set_params(best_params);
                obj.learn_svm(obj.signature.train_sigs, obj.class_id);                
                obj.precomputed_dist_file = [];
                write_log(sprintf('Best parameters:\nSVM C parameter = %f\nKernel parameter(s) = [%s]\n',best_params(1),sprintf('%.2f ',best_params(2:end))));   
                
                svm = obj.svm;
                save(file,'svm', 'cv_res');               
            end
        end
        
        %------------------------------------------------------------------
        % Learn the SVMs
        function obj = learn_svm(obj, train_sigs, class_id, do_pg)
            global USE_PARALLEL;
            
            n_classes = size(obj.class_names, 1);
            
            if nargin < 4
                 do_pg = 1;
            end
                
            if obj.OneVsOne
                n_models = n_classes*(n_classes-1)/2;
                lid = cell(n_models, 1);
                sigs = cell(n_models, 1);
                cur_model = 0;
                for i=1:n_classes
                    for j=(i+1):n_classes
                        cur_model = cur_model + 1;
                        i_pos = find(class_id == i);
                        i_neg = find(class_id == j);
                        lid{cur_model} = [ones(length(i_pos),1); -ones(length(i_neg),1)];
                        sigs{cur_model} = [train_sigs(i_pos,:); train_sigs(i_neg,:)];                                             
                    end 
                end
            else
                lid = cell(n_classes, 1);
                sigs = cell(n_classes, 1); 
                for i=1:n_classes
                    i_pos = find(class_id == i);
                    i_neg = find(class_id ~= i);
                    lid{i} = [ones(length(i_pos),1); -ones(length(i_neg),1)];
                    sigs{i} = [train_sigs(i_pos,:); train_sigs(i_neg,:)]; 
                end
            end

            if do_pg
                pg = ProgressBar('Training SVM', '');
            else
                pg = -1;
            end

            if 0 && USE_PARALLEL
                if do_pg
                    pg.setCaption('Training SVM...');
                end
                obj.svm = run_in_parallel('SVM.learn_parallel', struct('kernel', obj.kernel, 'C', obj.C, 'J', obj.J, 'file_precompute', obj.precomputed_dist_file), struct('labels', lid, 'sigs', sigs), 0, 0, pg, 0, 1);
            else
                n_models = size(lid, 1);
                obj.svm = cell(n_models, 1);
                for i=1:n_models
                    if do_pg
                        pg.setCaption(sprintf('Training SVM %d of %d...',i,n_models));
                        pg.progress(i/n_models);
                    end
                    obj.svm{i} = obj.kernel.learn(obj.C, obj.J, lid{i}, sigs{i}, obj.precomputed_dist_file);
                end
            end
            if do_pg
                pg.close();                
            end
        end
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        function [Ipaths classes correct_label assigned_label scores] = classify(obj, Ipaths, correct_label, do_pg)
            global USE_PARALLEL;
            
            classes = obj.class_names;
            n_classes = size(classes, 1);
            if nargin < 4
                 do_pg = 1;
            end
            if do_pg
                pg = ProgressBar('Classifying', 'Computing signatures...');
            else
                pg = -1;
            end
                        
            if nargin < 3
                [Ipaths l] = get_labeled_files(Ipaths, 'Loading testing set...\n');
                correct_label = names2ids(l, classes);    
                sigs = obj.signature.get_signatures(Ipaths, pg, 0, 0.7);
            else
                sigs = Ipaths;
            end
            
            n_img = size(sigs, 1);
            n_models = size(obj.svm, 1);
            
            if do_pg
                pg.setCaption('Assigning labels...');
            end
            assigned_label = zeros(n_img,1);
            
            if obj.OneVsOne
                if 0 && USE_PARALLEL
                    c = cell(n_models, 2);
                    cur_model = 0;
                    for i=1:n_classes
                        for j=i+1:n_classes                  
                            cur_model = cur_model + 1;
                            c{cur_model,1} = i;
                            c{cur_model,2} = j;
                        end
                    end                       
                    info = struct('kernel', obj.kernel, 'sigs', sigs, 'n_classes', n_classes, 'file_precompute', obj.precomputed_dist_file);
                    args = struct('svm', obj.svm, 'i', {c{:,1}}', 'j', {c{:,2}}');
                    res = run_in_parallel('SVM.classify_ovo_parallel', info,args, 0, 0, pg, 0.7, 0.3);
                    vote = sum(cat(3, res(:).vote),3);
                    scores = sum(cat(3, res(:).sc),3);
                else
                    vote = zeros(n_img,n_classes);
                    scores = zeros(n_img,n_classes);       
                    cur_model = 0;
                    for i=1:n_classes
                        for j=i+1:n_classes                  
                            cur_model = cur_model + 1;
                            if do_pg
                                pg.progress(0.7 + 0.3*cur_model/n_models);
                            end
                            
                            s = obj.kernel.classify(obj.svm{cur_model}, sigs, obj.precomputed_dist_file);

                            pos = s>=0;
                            neg = s<0;

                            vote(pos,i) = vote(pos,i) + 1;
                            vote(neg,j) = vote(neg,j) + 1;                       

                            scores(pos,i) = scores(pos,i) + s(pos);
                            scores(neg,i) = scores(neg,i) + s(neg);
                            scores(pos,j) = scores(pos,j) - s(pos);                            
                            scores(neg,j) = scores(neg,j) - s(neg);                         
                        end
                    end
                end
                for i=1:n_img                    
                    j = find(vote(i,:) == max(vote(i,:)));
                    [m k] = max(scores(i,j));
                    assigned_label(i) = j(k);
                end
            else % OneVsAll
                if 0 && USE_PARALLEL          
                    info = struct('kernel', obj.kernel, 'sigs', sigs, 'file_precompute', obj.precomputed_dist_file);
                    scores = run_in_parallel('SVM.classify_ova_parallel', info, obj.svm, 0, 0, pg, 0.7, 0.3)';  
                else
                    scores = zeros(n_img,n_classes);   
                    for i=1:n_classes
                        if do_pg
                            pg.progress(i/n_classes);
                        end
                        scores(:,i) = obj.kernel.classify(obj.svm{i}, sigs, obj.precomputed_dist_file);
                    end
                end
                for i=1:n_img
                    [m, j] = max(scores(i,:));
                    assigned_label(i) = j;
                end
            end      
            
            if do_pg
                pg.close();
            end
        end
               
        %------------------------------------------------------------------
        % Retrieves the training samples used for K-fold
        function samples = get_training_samples(obj)
            samples = [obj.class_id obj.signature.train_sigs];
        end
        
        %------------------------------------------------------------------
        % Retrieves all the values to test for cross-validation
        % 'params' must be a cell of vectors.
        function params = get_params(obj)
            
            [params do_cv] = obj.kernel.get_testing_params(obj.signature.train_sigs);
            
            if isempty(obj.C)
                params = [(1/mean(sum(obj.signature.train_sigs.*obj.signature.train_sigs,2)) * 2.^(-6:10))' params];
            elseif do_cv
                params = [obj.C params];
            else
                params = [];
            end
        end
        
        %------------------------------------------------------------------
        % Train on K-1 folds (stored in 'samples') with some value of parameters
        function model = CV_train(obj, params, samples)
            obj.set_params(params);
            model = obj.learn_svm(samples(:,2:end), samples(:,1), 0);
        end
        
        %------------------------------------------------------------------
        % Validate on the remaining fold
        function score = CV_validate(obj, model, samples)        
            [Ipaths classes correct_label assigned_label scores] = obj.classify(samples(:,2:end), samples(:,1), 0);
            score = get_precision(classes, correct_label, scores);
        end
        
        %------------------------------------------------------------------
        % Set C and kernel parameters        
        function obj = set_params(obj, params)
            obj.C = params(1);
            obj.kernel = obj.kernel.set_params(params(2:end));
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            if obj.OneVsOne
                strat = 'one VS one';
            else
                strat = 'one VS all';
            end
            if obj.param_cv(1)
                c = '?';
            else
                c = num2str(obj.C);
            end
            str = [sprintf('Classifier: SVM %s (C = %s, J = %s), %s, %d-fold cross-validation\n',strat, c, num2str(obj.J),obj.kernel.toString(), obj.K) obj.signature.toString()];
        end
        function str = toFileName(obj)
            if obj.OneVsOne
                strat = '1v1';
            else
                strat = '1vA';
            end
            if obj.param_cv(1)
                c = '?';
            else
                c = num2str(obj.C);
            end            
            str = sprintf('SVM[%s-%s-%s-%d-%s]-%s', strat, c, num2str(obj.J), obj.K, obj.kernel.toFileName(), obj.signature.toFileName());
        end
        function str = toName(obj)
            if obj.OneVsOne
                strat = '1v1';
            else
                strat = '1vA';
            end
            str = sprintf('SVM(%s)-%s', obj.kernel.toName(), strat);
        end        
    end
end
