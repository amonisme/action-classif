function test_SVM(use_cluster)
    global USE_PARALLEL SHOW_BAR USE_CLUSTER;
    USE_PARALLEL = 1;
    SHOW_BAR = 0;
    
    if nargin < 1
        use_cluster = 0;
    end
    
    
    % Channels
    n_channels = 2; channels = cell(2,1);
    channels{1} = Channels({MS_Dense()}, {SIFT(L2Trunc(), 'colorDescriptor')});
    channels{2} = Channels({MS_Dense()}, {SIFT(L2(), 'colorDescriptor')});
    
    signature = cell(9,n_channels);
    for i = 1:n_channels
        signature{1,i} = BOF(channels{i}, 256, L1());
        signature{2,i} = BOF(channels{i}, 256, L2());
        signature{3,i} = BOF(channels{i}, 256, None());
        signature{4,i} = BOF(channels{i}, 512, L1());
        signature{5,i} = BOF(channels{i}, 512, L2());
        signature{6,i} = BOF(channels{i}, 512, None());
        signature{7,i} = BOF(channels{i}, 1024, L1());
        signature{8,i} = BOF(channels{i}, 1024, L2());
        signature{9,i} = BOF(channels{i}, 1024, None());
    end
    
    kernels = cell(3,1);
    kernels{1} = Linear();
    kernels{2} = Chi2();
    kernels{3} = RBF();
    
    strat = cell(2,1);
    strat{1} = 'OneVsOne';
    strat{2} = 'OneVsAll';
    
    n_sig = numel(signature);
    n_ker = size(kernels, 1);
    n_strat = size(strat,1);    
    
    if USE_PARALLEL
        use_para = 'ON';
    else
        use_para = 'OFF';
    end
    fprintf('Found %d classifiers to test. Let''s go for the overnight computation!!!\nParallel computing is %s.\n\n', n_sig*n_ker*n_strat, use_para);
    
    database = '../../DataBase/';
    
    if use_cluster
        USE_CLUSTER = 1;
        dir = '../../test_SVM';
        
        % Cache signatures
        classifiers = cell(n_sig,3);        
        for i = 1:n_sig
            classifiers{i,1} = SVM(kernels{1}, signature{i}, strat{1}, [], 1, 5);           
            classifiers{i,2} = database;
            classifiers{i,3} = dir;              
        end
        run_in_parallel('evaluate_parallel',[],classifiers,[]);
              
        % Full classify
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
        run_in_parallel('evaluate_parallel',[],classifiers,[]);
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
