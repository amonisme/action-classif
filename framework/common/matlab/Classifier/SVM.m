
classdef SVM < ClassifierAPI & CrossValidateAPI
    % Support Vector Machine Classifier

    properties (SetAccess = protected)
        signature   % Signature module
        C 	        % trade-off between training error and margin (if -1, then set to default [avg. x*x]^-1, set to [] for cross-validation)
        J	        % Cost-factor, by which training errors on positive examples outweight errors on negative examples (default 1)
        K           % K-fold cross-validation
        param_cv    % remember which parameterter was cross-validated
        OneVsOne    % 1 - 1vs1  // 0 - 1vsA
        kernel        
        svm
        labels                
    end
        
    methods (Static = true)         
        %------------------------------------------------------------------
        function svm = learn_parallel(info, args)
            tid = task_open();
            
            n_models = size(args, 1);
            svm = cell(n_models, 1);
            for i=1:n_models
                svm{i} = info.kernel.learn(info.C, info.J, args(i).labels, args(i).sigs);
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
                s = info.kernel.classify(args(k).svm, info.sigs);

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
                sc(k,:) = info.kernel.classify(svm{k}, info.sigs)';
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
                res(i) = info.obj.K_fold_cross_validate(info.train_sigs, info.labels, info.folds, info.file);
                task_progress(tid,i/n_params);
            end           

            task_close(tid);
        end        
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SVM(signatures, kernels, strat, C, J, K)
            if(nargin < 3)
                strat = 'OneVsAll';
            end
            if(nargin < 4)
                C = [];
            end
            if(nargin < 5)
            	J = 1;
            end
            if(nargin < 6)
            	K = 5;
            end
            
            if length(kernels) ~= 1  && length(kernels) ~= length(signatures)
                throw(MException('','In case of multi-kernels, there should be as many kernels as signatures.\n'));
            end            
            
            if length(kernels) == 1            
                obj.kernel = kernels{1};
            else
                obj.kernel = MultiKernel(signatures, kernels);
            end
            obj.signature = signatures;
            obj.C = C;
            obj.J = J;
            obj.K = K;
            
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
        function [cv_prec cv_dev_prec cv_acc cv_dev_acc] = learn(obj, root)
            global HASH_PATH TEMP_DIR;
            
            [images map c_names subc_names] = get_labeled_files(root, 'Loading training set...\n');            
            obj.store_names(c_names, subc_names, map);                  
            obj.labels = cat(1,images(:).actions);
            
            write_log('Learn signatures...\n');
            n_sigs = length(obj.signature);
            for i = 1:n_sigs
                obj.signature{i}.learn(images);
            end
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.toFileName()));
            
            ok = 0;
            if exist(file,'file') == 2  
                write_log(sprintf('Loading classifier from cache: %s.\n', file));
                load(file, 'svm', 'best_params', 'cv_prec', 'cv_dev_prec', 'cv_acc', 'cv_dev_acc');
                if exist('best_params', 'var') == 1
                  obj.svm = svm;
                  obj.C = best_params(1);
                  obj.kernel.set_params(best_params(2:end));
                  write_log(sprintf('Loaded.\n'));
                  ok = 1;
                else
                    write_log(sprintf('Failed.\n'));
                end                
            end
            if ~ok             
                if obj.C == -1
                    n_sigs = length(obj.signature);
                    sigs = obj.signature{1}.train_sigs;
                    for i = 2:n_sigs
                        sigs = [sigs; obj.signature{i}.train_sigs];
                    end
                    obj.C = 1/mean(sum(sigs.*sigs,1));
                    clear sigs;
                end
                
                % Precompute distance        
                [params best_params cv_prec cv_dev_prec cv_acc cv_dev_acc] = cross_validate(obj, obj.K);                
                obj.CV_set_params(best_params);
                n_sigs = length(obj.signature);
                sigs = cell(n_sigs, 1);
                for i = 1:n_sigs
                    sigs{i} = obj.signature{i}.train_sigs;
                end     

                if ~isa(obj.kernel, 'MultiKernel')
                    sigs = cat(1,sigs{:});
                end
            
                obj.learn_svm(obj.kernel.get_kernel_sigs(sigs), obj.labels);                
                svm = obj.svm; 
                save(file,'svm', 'params', 'best_params', 'cv_prec', 'cv_dev_prec', 'cv_acc', 'cv_dev_acc');
                
                write_log(sprintf('Best parameters:\nSVM C parameter = %f\n',obj.C));
                write_log(sprintf('Kernel parameter(s) = [%s]\n',sprintf('%.2f ',best_params(2:end))));   
            end
        end
        
        %------------------------------------------------------------------
        % Learn the SVMs
        function obj = learn_svm(obj, train_sigs, labels, do_pg)
            global USE_PARALLEL;
            
            n_classes = size(obj.subclasses_names, 1);
            
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
                        i_pos = find(labels(:,i));
                        i_neg = find(labels(:,j));
                        lid{cur_model} = [ones(length(i_pos),1); -ones(length(i_neg),1)];
                        sigs{cur_model} = [train_sigs(:,i_pos) train_sigs(:,i_neg)];                                             
                    end 
                end
            else
                lid = cell(n_classes, 1);
                sigs = cell(n_classes, 1); 
                for i=1:n_classes
                    i_pos = find(labels(:,i));
                    i_neg = find(~labels(:,i));
                    lid{i} = [ones(length(i_pos),1); -ones(length(i_neg),1)];
                    sigs{i} = [train_sigs(:,i_pos) train_sigs(:,i_neg)]; 
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
                obj.svm = run_in_parallel('SVM.learn_parallel', struct('kernel', obj.kernel, 'C', obj.C, 'J', obj.J), struct('labels', lid, 'sigs', sigs), 0, 0, pg, 0, 1);
            else
                n_models = size(lid, 1);
                obj.svm = cell(n_models, 1);
                for i=1:n_models
                    if do_pg
                        pg.setCaption(sprintf('Training SVM %d of %d...',i,n_models));
                        pg.progress(i/n_models);
                    end                   
                    obj.svm{i} = obj.kernel.learn(obj.C, obj.J, lid{i}, sigs{i});
                end
            end
            if do_pg
                pg.close();                
            end
        end
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        function [images classes subclasses map_sub2sup assigned_action scores] = classify(obj, root_images, correct_labels)
            global USE_PARALLEL;                    
                              
            if ischar(root_images)
                pg = ProgressBar('Classifying', '');
                do_pg = 1;
                
                [images map_sub2sup classes subclasses] = get_labeled_files(root_images, 'Loading testing set...\n');   

                n_sigs = length(obj.signature);
                sigs = cell(n_sigs,1);
                for i = 1:n_sigs
                    sigs{i} = obj.signature{i}.get_signatures(images, pg, 0.7/n_sigs*(i-1), 0.7/n_sigs);
                end                
                
                if ~isa(obj.kernel, 'MultiKernel')
                    train_sigs = cell(n_sigs, 1);
                    for i = 1:n_sigs
                        train_sigs{i} = obj.signature{i}.train_sigs;
                    end                     
                    sigs = cat(1,sigs{:});
                    train_sigs = cat(1, train_sigs{:});
                    obj.kernel.compute_gram_matrix(train_sigs, sigs);                    
                else                                       
                    obj.kernel.compute_gram_matrix(obj.signature, sigs);
                end                
                sigs = obj.kernel.get_kernel_sigs(sigs);
            else                
                pg = -1;
                do_pg = 0;
                sigs = root_images;                               
                classes = obj.classes_names;
                subclasses = obj.subclasses_names;
                map_sub2sup = obj.map_sub2sup;                
                n_img = size(correct_labels,1);
                images = struct('actions', cell(n_img,1));
                for i = 1:n_img
                    images(i).actions = correct_labels(i,:);
                end
            end
            n_classes = size(subclasses, 1);           
                       
            n_img = size(sigs, 2);
            n_models = size(obj.svm, 1);
            
            if do_pg
                pg.setCaption('Assigning labels...');
            end
            assigned_action = zeros(n_img,size(obj.labels, 2));
            
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
                    info = struct('kernel', obj.kernel, 'sigs', sigs, 'n_classes', n_classes);
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
                            
                            s = obj.kernel.classify(obj.svm{cur_model}, sigs);

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
                    assigned_action(i,j(k)) = 1;
                end
            else % OneVsAll
                if 0 && USE_PARALLEL          
                    info = struct('kernel', obj.kernel, 'sigs', sigs);
                    scores = run_in_parallel('SVM.classify_ova_parallel', info, obj.svm, 0, 0, pg, 0.7, 0.3)';  
                else
                    scores = zeros(n_img,n_classes);   
                    for i=1:n_classes
                        if do_pg
                            pg.progress(i/n_classes);
                        end
                        scores(:,i) = obj.kernel.classify(obj.svm{i}, sigs);
                    end
                end
                for i=1:n_img
                    [m, j] = max(scores(i,:));
                    assigned_action(i,j) = 1;
                end
            end      
            
            if do_pg
                pg.close();
            end
        end
               
        %------------------------------------------------------------------
        % Retrieves the training samples used for K-fold
        function samples = CV_get_training_samples(obj)
            n_sigs = length(obj.signature);
            sigs = cell(n_sigs, 1);
            for i = 1:n_sigs
                sigs{i} = obj.signature{i}.train_sigs;
            end     
            
            if ~isa(obj.kernel, 'MultiKernel')
                sigs = cat(1,sigs{:});
            end
            cv_sigs = obj.kernel.get_kernel_sigs(sigs);
            
            samples = [obj.labels'; cv_sigs];
        end
        
        %------------------------------------------------------------------
        % Train on K-1 folds (stored in 'samples') with some value of parameters
        function model = CV_train(obj, samples)
            model = obj.learn_svm(samples((1+size(obj.labels,2)):end,:), samples(1:size(obj.labels,2),:)', 0);
        end
        
        %------------------------------------------------------------------
        % Validate on the remaining fold
        function [prec acc] = CV_validate(obj, model, samples)     
            [images classes subclasses map_sub2sup assigned_action scores] = obj.classify(samples((1+size(obj.labels,2)):end,:), samples(1:size(obj.labels,2),:)');
            correct_labels = cat(1, images(:).actions);
            prec = get_precision(classes, correct_labels, scores);
            acc = get_accuracy(confusion_table(correct_labels, assigned_action));
        end
        
        %------------------------------------------------------------------
        % Retrieves all the values to test for cross-validation
        % 'params' must be a cell of vectors.
        function params = CV_get_params(obj)
            sigs = obj.signature{1}.train_sigs;
            for i = 2:length(obj.signature)
                sigs = [sigs; obj.signature{i}.train_sigs];
            end
            
            if ~isa(obj.kernel, 'MultiKernel')
                params = obj.kernel.get_params(sigs);
            else
                params = obj.kernel.get_params(obj.signature);
            end
                       
            if isempty(obj.C)
                p = 1/mean(sum(sigs.*sigs,1));
                params = [(p * 1.5.^(-6:6))'; params];
            else
                params = [obj.C; params];
            end
        end
        
        %------------------------------------------------------------------
        % Set C and kernel parameters        
        function obj = CV_set_params(obj, params)
            obj.C = params(1);
            obj.kernel.set_params(params(2:end));
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
                c = 'cv';
            else
                c = num2str(obj.C);
            end
          
            if isa(obj.kernel, 'MultiKernel')
                str_ker = obj.kernel.toString();
            else
                n_sigs = length(obj.signature); 
                str = cell(1, n_sigs);
                for i=1:n_sigs
                    str{i} = obj.signature{i}.toString();
                    str{i} = sprintf('$~~~~$%s\n', str{i});
                end
                str = cat(2,str{:});            
                str_ker = sprintf('%s:\n%s', obj.kernel.toString(), str);
            end
            
            str = sprintf('Classifier: SVM %s (C = %s, J = %s) %d-fold cross-validation\n%s',strat, c, num2str(obj.J), obj.K, str_ker);
        end
        
        function str = toFileName(obj)
            if obj.OneVsOne
                strat = '1v1';
            else
                strat = '1vA';
            end
            if obj.param_cv(1)
                c = 'cv';
            else
                c = num2str(obj.C);
            end            
            
            if isa(obj.kernel, 'MultiKernel')
                str_ker = obj.kernel.toFileName();
            else
                n_sigs = length(obj.signature);                 
                if n_sigs == 1
                    str_ker = sprintf('%s-%s', obj.kernel.toFileName(), obj.signature{1}.toFileName());
                else
                    str = cell(1, n_sigs);
                    for i=1:n_sigs
                        str{i} = obj.signature{i}.toFileName();
                        if i ~= 1
                            str{i} = ['-' str{i}];
                        end
                    end
                    str = cat(2,str{:});            
                    str_ker = sprintf('%s-(%s)', obj.kernel.toFileName(), str);
                end
            end
            str = sprintf('SVM[%s-%s-%s-%d]-%s', strat, c, num2str(obj.J), obj.K, str_ker);  
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
