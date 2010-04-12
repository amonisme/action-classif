function test_PYR_Chi2(use_cluster)
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
    
    kernel = Chi2();
    auto_weight = 1;
    
    signature = cell(9,n_channels,3);
    for i = 1:n_channels
        for L = 1:3
            levels = (0:L)';
            if auto_weight
                w = zeros(size(levels));
            else
                w = 1./2.^(L-levels+1);
                w(1) = 1/2^L;
            end
            grid = [2.^levels, 2.^levels, w];            
            
            signature{1,i,L} = BOF(channels{i}, 256, L1(), grid);
            signature{2,i,L} = BOF(channels{i}, 256, L2(), grid);
            signature{3,i,L} = BOF(channels{i}, 256, None(), grid);
            signature{4,i,L} = BOF(channels{i}, 512, L1(), grid);
            signature{5,i,L} = BOF(channels{i}, 512, L2(), grid);
            signature{6,i,L} = BOF(channels{i}, 512, None(), grid);
            signature{7,i,L} = BOF(channels{i}, 1024, L1(), grid);
            signature{8,i,L} = BOF(channels{i}, 1024, L2(), grid);
            signature{9,i,L} = BOF(channels{i}, 1024, None(), grid);
        end
    end
       
    strat = cell(2,1);
    strat{1} = 'OneVsOne';
    strat{2} = 'OneVsAll';
    
    n_sig = numel(signature);
    n_strat = size(strat,1);    
    
    if USE_PARALLEL
        use_para = 'ON';
    else
        use_para = 'OFF';
    end
    fprintf('Found %d classifiers to test. Let''s go for the overnight computation!!!\nParallel computing is %s.\n\n', n_sig*n_strat, use_para);
    
    database = '../../DataBase/';
    
    if(use_cluster)
        USE_CLUSTER = 1;
        dir = '../../test_PYR';
        
        % 1v1
        classifiers = cell(n_sig,3);        
        for i = 1:n_sig
            classifiers{i,1} = SVM(kernel, signature{i}, strat{1}, [], 1, 5);           
            classifiers{i,2} = database;
            classifiers{i,3} = dir;              
        end
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);
        
        % 1vA
        classifiers = cell(n_sig,3);        
        for i = 1:n_sig
            classifiers{i,1} = SVM(kernel, signature{i}, strat{2}, [], 1, 5);           
            classifiers{i,2} = database;
            classifiers{i,3} = dir;              
        end
        run_in_parallel('evaluate_parallel',[],classifiers,[],0);        
    else   
        dir = 'baseline/test_PYR';
        [status,message,messageid] = mkdir(dir);
        fid = fopen(fullfile(dir, 'log.txt'), 'w+');   

        for i = 1:n_sig
            for k=1:n_strat
                classifier = SVM(kernel, signature{i}, strat{k}, [], 1, 5);           
                try
                    evaluate(classifier, database, dir);
                catch ME
                    fprintf(fid, sprintf('%s\nFAIL: %s\nLOCATION: %s:%d\nParameters:\n%s\n\n', classifier.toFileName(), ME.message, ME.stack(1).file, ME.stack(1).line, classifier.toString()));
                end                
            end
        end
        fclose(fid);
    end
end
