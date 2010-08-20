function test_VOC_BOF(db)
    if nargin < 1
        db = {'train' 'test'};
    end

    global USE_PARALLEL;

    set_cluster_config();

    cd '/data/vdelaitr/src/framework';
    USE_PARALLEL = 0;
    USE_CLUSTER = 0;

    L = 2;

    levels = (0:L)';
    w = 1./2.^(L-levels+1);
    w(1) = 1/2^L;
    grid = [2.^levels, 2.^levels, w];  

    classif = SVM({BOF(MS_Dense(12), SIFT(L2Trunc()), 1024, L1(), grid, 1, 0), ...
                   BOF(MS_Dense(12), SIFT(L2Trunc()), 1024, L1(), grid, 0, 0)}, ...
                   {Intersection(1) Intersection(1)});

    evaluate(classif, '/data/vdelaitr/VOCdevkit/VOC2010', [], sprintf('VOC_%s-%s', db{1}, db{2}), db);  
end