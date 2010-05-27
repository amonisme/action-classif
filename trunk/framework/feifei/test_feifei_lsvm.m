function test_feifei_lsvm(db)
    cd '/data/vdelaitr/src/framework';
    set_cluster_config;
    global USE_PARALLEL SHOW_BAR FILE_BUFFER_PATH;
    %USE_PARALLEL = 1;
    SHOW_BAR = 1;    
    FILE_BUFFER_PATH = '../../temp';

    classifier = LSVM(1,8);
    
    evaluate(classifier, '/data/vdelaitr/FeiFeiNorm', db, fullfile('/data/vdelaitr/', sprintf('LSVM_%s', db)));
end