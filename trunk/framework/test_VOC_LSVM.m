function test_VOC_LSVM(db)
    if nargin < 1
        db = {'train' 'test'};
    end

    cd('/data/vdelaitr/src/framework');

    set_cluster_config;
    global USE_PARALLEL USE_CLUSTER;

    USE_PARALLEL = 0;
    USE_CLUSTER = 0;

    evaluate(LSVM(3,8), '/data/vdelaitr/VOCdevkit/VOC2010', [], sprintf('../../VOC_%s-%s', db{1}, db{2}), db);  
end