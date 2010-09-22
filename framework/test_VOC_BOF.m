function test_VOC_BOF(db)
    if nargin < 1
        db = {'train' 'test'};
    end

    global USE_PARALLEL;

    set_cluster_config();

    cd '/data/vdelaitr/src/framework';
    
    L = 2;

    levels = (0:L)';
    w = 1./2.^(L-levels+1);
    w(1) = 1/2^L;
    grid = [2.^levels, 2.^levels, w];  

    %classif = SVM({BOF(MS_Dense(8), SIFT(L2Trunc()), 256, L1(), grid, 1, 0), ...
    %               BOF(MS_Dense(8), SIFT(L2Trunc()), 256, L1(), grid, 0, 0)}, ...
    %              {Intersection(1) Intersection(1)});
    classif = SVM({BOF(MS_Dense(8,1.44,5), SIFT(L2Trunc()), 256, L1(), grid, 1, 0)}, {Linear});
                            
    fprintf('%s', classif.toFileName());

    USE_PARALLEL = 1;
    USE_CLUSTER = 1;               
    
    if 0    
        param = cell(1,5);
        param{1,1} = classif;          
        param{1,2} = '/data/vdelaitr/VOCdevkit/VOC2010';
        param{1,3} = []; 
        param{1,4} = sprintf('../../VOC_%s-%s', db{1}, db{2});
        param{1,5} = db;
        run_in_parallel('evaluate_parallel',[],param,[],8000);    
    else
        evaluate(classif, '/data/vdelaitr/VOCdevkit/VOC2010', [], sprintf('../../VOC_%s-%s', db{1}, db{2}), db);  
    end
end
