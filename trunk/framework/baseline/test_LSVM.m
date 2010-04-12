function test_LSVM
    global USE_PARALLEL USE_CLUSTER SHOW_BAR;
    %set_cluster_config();
    USE_CLUSTER = 0;
    USE_PARALLEL = 1;
    SHOW_BAR = 1;

    classifier = LSVM();
    
    database = '../../DataBase/';
    dir = '../../test_LSVM';
    evaluate(classifier, database, dir);
end

