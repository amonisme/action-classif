function test_BOFLSVM(db, set)
    classif = BOFLSVM(256,3,8,'A');
    
    if nargin < 2
        set = {'train' 'test'};
    end       
      
    [d name] = fileparts(db);       
    path_results = sprintf('/data/vdelaitr/results/%s/%s-%s', name, set{1}, set{2});

    global USE_PARALLEL USE_CLUSTER;
    USE_PARALLEL = 1;
    USE_CLUSTER = 1;        
    
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
