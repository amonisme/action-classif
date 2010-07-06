function test_feifei_svm(db, size, levels)
    cd '/data/vdelaitr/src/framework';
    set_cluster_config;
    global USE_PARALLEL SHOW_BAR FILE_BUFFER_PATH;
    USE_PARALLEL = 1;
    SHOW_BAR = 1;    
    FILE_BUFFER_PATH = '../../temp';

    classifier = LogisticSVM({BOF(MS_Dense(6), SIFT(L2Trunc), size, L1, levels)}, {Intersection});
    
    evaluate(classifier, '/data/vdelaitr/FeiFeiNorm', db, fullfile('/data/vdelaitr/', sprintf('SVM_%s', db)));
end