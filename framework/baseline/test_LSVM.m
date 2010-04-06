function test_LSVM
    global USE_PARALLEL USE_CLUSTER SHOW_BAR;
    USE_PARALLEL = 1;
    USE_CLUSTER = 1;
    SHOW_BAR = 1;

    classifier = LSVM();
    
    database = '../../DataBase/';
    dir = 'baseline/test_SVM';
    evaluate(classifier, database, dir);
end

