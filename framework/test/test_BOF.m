function test_BOF(db, set)
    L = 2;
    levels = (0:L)';
    w = 1./2.^(L-levels+1);
    w(1) = 1/2^L;
    grid = [2.^levels, 2.^levels, w];  
    
    classif = SVM({BOF(MS_Dense(12), SIFT(L2Trunc()), 1024, L1(), grid, 1, 300), ...
                   BOF(MS_Dense(12), SIFT(L2Trunc()), 1024, L1(), grid, -1, 300)}, ...
                  {Intersection(1) Intersection(1)});
    %classif = SVM({BOF(MS_Dense(8,1.44,5), SIFT(L2Trunc()), 256, L1(), grid, 1, 0)}, {Linear});    

    if nargin < 2
        set = {'train' 'test'};
    end       
      
    [d name] = fileparts(db);       
    path_results = sprintf('/data/vdelaitr/results/%s/%s-%s', name, set{1}, set{2});

    global USE_PARALLEL USE_CLUSTER;
    USE_PARALLEL = 0;
    USE_CLUSTER = 0;        
    
    if 0 
        param = cell(1,4);
        param{1} = classif;
        param{2} = db;
        param{3} = path_results;
        param{4} = set;
        run_in_parallel('evaluate_parallel', [], param, [], 4000);
    else
        evaluate(classif, db, path_results, set);   
    end 
end
