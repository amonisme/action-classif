function test_BMVC_LSVM(use_cluster)
    if nargin < 1
        use_cluster = 0;
    end

    db = {'../../DataBaseCropped' '../../DataBaseNoCrop' '../../DataBaseNoCropResize'};
    n_db = length(db);
    
    K = 3;
    classif = cell(length(db)*K,3);
      
    for i = 1:n_db
        i0 = (i-1)*K;
        for j = 1:K
            classif(i0+j, 1) = LSVM(j);
            classif{i0+j, 2} = db{i};
            classif{i0+j, 3} = sprintf('%s_test_LSVM',db{i});
        end
    end
    
    if(use_cluster)
        run_in_parallel('evaluate_parallel',[],classif,[],0);
    else
        for i = 1:size(classif,1)
            evaluate(classif{i,1}, classif{i,2}, classif{i,3});
        end
    end
end