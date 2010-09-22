function test_VOC_hybrid(db)
    if nargin < 1
        db = {'train' 'test'};
    end

    global USE_PARALLEL USE_CLUSTER;

    set_cluster_config();

    cd '/data/vdelaitr/src/framework';
    USE_PARALLEL = 0;
    USE_CLUSTER = 0;
    
    evaluate(BOFLSVM(256,3,0,'H'), '/data/vdelaitr/VOCdevkit/VOC2010', [], sprintf('../../VOC_%s-%s', db{1}, db{2}), db);  
end