function test_BMVC_LSVM(db_id, use_cluster)
    if nargin < 1
        use_cluster = 0;
    end
    
    db = {'../../DataBaseCropped', ...
          '../../DataBaseNoCrop', ...
          '../../DataBaseNoCropResize', ...
          '../../DBGupta', ...
          '../../DBGuptaResize'};      
    dir = {'../../DataBaseCropped_test_LSVM', ...
           '../../DataBaseNoCrop_test_LSVM', ...
           '../../DataBaseNoCropResize_test_LSVM', ...
           '../../DBGupta_test_LSVM', ...
           '../../DBGuptaResize_test_LSVM'};
    
    K = 3;
    classif = cell(K,3);
      
    for i = K:-1:1    
        i0 = K-i+1;
        classif{i0, 1} = LSVM(i);
        classif{i0, 2} = db{db_id};
        classif{i0, 3} = dir{db_id};
    end
    
    if(use_cluster)
        run_in_parallel('evaluate_parallel',[],classif,[],0);
    else
        for i = 1:size(classif,1)
            evaluate(classif{i,1}, classif{i,2}, classif{i,3});
        end
    end
end