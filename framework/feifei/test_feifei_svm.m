function test_feifei_svm(db)
    cd '/data/vdelaitr/src/framework';
    set_cluster_config;
    global USE_PARALLEL SHOW_BAR FILE_BUFFER_PATH;
    USE_PARALLEL = 1;
    SHOW_BAR = 1;    
    FILE_BUFFER_PATH = '../../temp';

    classifier = SVM({BOF(MS_Dense, SIFT(L2Trunc), 1024, L1, 2)}, {Intersection});
    
    evaluate(classifier, '/data/vdelaitr/FeiFeiNorm', db, fullfile('/data/vdelaitr/', sprintf('SVM_%s', db)));
end