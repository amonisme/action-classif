function test_SVM(use_cluster, database)
    global USE_PARALLEL SHOW_BAR USE_CLUSTER;
    USE_PARALLEL = 1;
    SHOW_BAR = 0;
    
    if nargin < 1
        use_cluster = 0;
    end
    if nargin < 2
        database = '../../DataBaseCropped/';
    end
    
    
    % Channels
    n_channels = 2; channels = cell(2,1);
    channels{1} = Channels({MS_Dense()}, {SIFT(L2Trunc())});
    channels{2} = Channels({MS_Dense()}, {SIFT(L2())});
    
    % Dictionnary sizes
    sizes = [256 512 1024 2048 4096];
    n_sizes = length(sizes);
    
    % Norms signatures
    norms_s = {
        L1(), ...
        L2(), ... 
        None() ...      
    };    
    n_norms_s = length(norms_s);
    
    signature = cell(n_channels, n_sizes, n_norms_s);
    for i = 1:n_channels
        for j = 1:n_sizes
            for k = 1:n_norms_s
                signature{i,j,k} = BOF(channels{i}, sizes(j), norms_s{k});
            end
        end
    end
        
    kernels = {Linear(1), ...
               Intersection(1), ...
               Chi2([],1), ...
               RBF([],1)};
    
    strat = cell(2,1);
    strat{1} = 'OneVsOne';
    strat{2} = 'OneVsAll';  
    
    n_sig = numel(signature);
    n_ker = length(kernels);
    n_strat = length(strat);
    
    if USE_PARALLEL
        use_para = 'ON';
    else
        use_para = 'OFF';
    end
    fprintf('Found %d classifiers to test. Let''s go for the overnight computation!!!\nParallel computing is %s.\n\n', n_sig*n_ker*n_strat, use_para);
    
    if use_cluster
        USE_CLUSTER = 1;
        dir = '../../test_SVM';
        
        % Cache dictionnary
%         classifiers = cell(n_channels*n_sizes,3);        
%         for i = 1:n_channels*n_sizes
%             classifiers{i,1} = SVM(kernels{1}, signature{i}, strat{1}, [], 1, 5);           
%             classifiers{i,2} = database;
%             classifiers{i,3} = dir;              
%         end
%         run_in_parallel('evaluate_parallel',[],classifiers,[],0);
              
        % Full test
        classifiers = cell(n_ker*n_strat*n_sig,3);   
        for k = 1:n_ker
            for j=1:n_strat
                for i = 1:n_sig
                    classifiers{(k-1)*n_strat*n_sig + (j-1)*n_sig + i,1} = SVM(kernels{k}, signature{i}, strat{j}, [], 1, 5);           
                    classifiers{(k-1)*n_strat*n_sig + (j-1)*n_sig + i,2} = database;
                    classifiers{(k-1)*n_strat*n_sig + (j-1)*n_sig + i,3} = dir;
                end
            end
        end    
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);
    else
        dir = 'baseline/test_SVM';
        [status,message,messageid] = mkdir(dir);
        fid = fopen(fullfile(dir, 'log.txt'), 'w+');   

        for i = 1:n_sig
            for j=1:n_strat
                for k = 1:n_ker
                    classifier = SVM(kernels{k}, signature{i}, strat{j}, [], 1, 5);           
                    try
                        evaluate(classifier, database, dir);
                    catch ME
                        fprintf(fid, sprintf('%s\nFAIL: %s\nLOCATION: \n', classifier.toFileName(), ME.message));
                        for stackc = 1:length(ME.stack)
                            fprintf(fid, sprintf('%s:%d\n', ME.stack(stackc).file, ME.stack(stackc).line));
                        end
                        fprintf(fid, sprintf('Parameters:\n%s\n\n', classifier.toString()));
                    end                
                end
            end
        end
        fclose(fid);
    end
end
