function test_KNN(use_cluster)
    global USE_PARALLEL SHOW_BAR USE_CLUSTER;
    USE_PARALLEL = 1;
    SHOW_BAR = 0;
    
    if nargin < 1
        use_cluster = 0;
    end
    
    % Channels   
    channels = {
        Channels({Harris('S')},  {SIFT(L2())}), ...
        Channels({Harris('S')},  {SIFT(L2Trunc())}), ...    
        Channels({Harris('SR')}, {SIFT(L2())}), ...
        Channels({Harris('SR')}, {SIFT(L2Trunc())}), ...    
        Channels({Dense()},      {SIFT(L2())}), ...
        Channels({Dense()},      {SIFT(L2Trunc())}), ...    
        Channels({MS_Dense()},   {SIFT(L2())}), ...
        Channels({MS_Dense()},   {SIFT(L2Trunc())}) ...
    }';
    n_channels = size(channels,1);
         
    % Dictionnary sizes
    sizes = [128 256 512 1024]';
    n_sizes = size(sizes,1);
    
    % Norms signatures
    norms_s = {
        L1(), ...
        L2(), ... 
        None() ...      
    }';    
    n_norms_s = size(norms_s, 1);
    
    % K for KNN
    K = (1:5)';
    n_K = size(K,1);
    
    
    if USE_PARALLEL
        use_para = 'ON';
    else
        use_para = 'OFF';
    end
    fprintf('Found %d classifiers to test. Let''s go for the overnight computation!!!\nParallel computing is %s.\n\n', n_channels*n_sizes*n_K*n_norms_s, use_para);
    
    database = '../../DataBase/';
    
    if use_cluster
        USE_CLUSTER = 1;
        dir = '../../test_KNN';
        
        % Cache channels
        classifiers = cell(n_channels,3);
        for i = 1:n_channels
            classifiers{i,1} = NN(BOF(channels{i}, sizes(1), norms_s{1}));
            classifiers{i,2} = database;
            classifiers{i,3} = dir;
        end
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);
        
        % Cache Kmeans
        classifiers = cell(n_channels*n_sizes,3);
        for j = 1:n_sizes
            for i = 1:n_channels
                classifiers{(j-1)*n_channels + i,1} = NN(BOF(channels{i}, sizes(j), norms_s{1}));
                classifiers{(j-1)*n_channels + i,2} = database;
                classifiers{(j-1)*n_channels + i,3} = dir;
            end
        end
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);
        
        % Cache signatures
        classifiers = cell(n_channels*n_sizes*n_norms_s,3);
        for x = 1:n_norms_s
            for j = 1:n_sizes
                for i = 1:n_channels
                    classifiers{(x-1)*n_sizes*n_channels + (j-1)*n_channels + i,1} = NN(BOF(channels{i}, sizes(j), norms_s{1}));
                    classifiers{(x-1)*n_sizes*n_channels + (j-1)*n_channels + i,2} = database;
                    classifiers{(x-1)*n_sizes*n_channels + (j-1)*n_channels + i,3} = dir;
                end
            end
        end
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);
        
        % Full classify
        for k = 1:n_K
            for x = 1:n_norms_s
                for j = 1:n_sizes
                    for i = 1:n_channels 
                        if k == 1
                            classifiers{(k-1)*n_norms_s*n_sizes*n_channels + (x-1)*n_sizes*n_channels + (j-1)*n_channels + i,1} = NN(BOF(channels{i}, sizes(j), norms_s{x}));
                        else
                            classifiers{(k-1)*n_norms_s*n_sizes*n_channels + (x-1)*n_sizes*n_channels + (j-1)*n_channels + i,1} = KNN(K(k), BOF(channels{i}, sizes(j), norms_s{x}));
                        end
                        classifiers{(k-1)*n_norms_s*n_sizes*n_channels + (x-1)*n_sizes*n_channels + (j-1)*n_channels + i,2} = database;
                        classifiers{(k-1)*n_norms_s*n_sizes*n_channels + (x-1)*n_sizes*n_channels + (j-1)*n_channels + i,3} = dir;
                    end
                end
            end
        end    
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);
    else
        dir = 'baseline/test_KNN';
        [status,message,messageid] = mkdir(dir);
        fid = fopen(fullfile(dir, 'log.txt'), 'w+');
    
        for k = 1:n_K
            for x = 1:n_norms_s
                for j = 1:n_sizes
                    for i = 1:n_channels 
                        if k == 1
                            classifier = NN(BOF(channels{i}, sizes(j), norms_s{x}));
                        else
                            classifier = KNN(K(k), BOF(channels{i}, sizes(j), norms_s{x}));
                        end
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
        end
        
        fclose(fid);
    end
end
