function test_LSVM(n, use_cluster)
    global USE_PARALLEL USE_CLUSTER SHOW_BAR;
    %set_cluster_config();
    
    USE_PARALLEL = 0;
    SHOW_BAR = 1;
    
    if nargin < 2
        use_cluster = 0;
    end
   
    database = '../../DataBase/';
    dir = '../../test_LSVM_new';
    
    if use_cluster
        USE_CLUSTER = 1;
        
        classifier = cell(1,3);        
        classifier{1,1} = LSVM(n);         
        classifier{1,2} = database;
        classifier{1,3} = dir;   
            
        run_in_parallel('evaluate_parallel',[],classifier,[],4096);
    else
        USE_CLUSTER = 0;    
        evaluate(LSVM(n), database, dir);
    end
end

