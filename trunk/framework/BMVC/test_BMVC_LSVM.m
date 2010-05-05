function test_BMVC_LSVM(db_id, n_compo, n_parts, use_cluster)
    global USE_PARALLEL;
    USE_PARALLEL = 1;
    
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
    
    classif = cell(1,3);
      
    i0 = 1;
    classif{i0, 1} = LSVM(n_compo,n_parts);
    classif{i0, 2} = db{db_id};
    classif{i0, 3} = dir{db_id};
        
    for i = 1:size(classif,1)
        evaluate(classif{i,1}, classif{i,2}, classif{i,3});
    end
end