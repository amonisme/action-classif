function test_BMVC(use_cluster)
    if nargin < 1
        use_cluster = 0;
    end

    [classif_BOF classif_PYR] = get_paper_BMVC_classif();
    n_classif_BOF = length(classif_BOF);
    n_classif_PYR = length(classif_PYR);
    n_classif = n_classif_BOF + n_classif_PYR;
    
    db = {'../../DataBaseCropped' '../../DataBaseNoCrop' '../../DataBaseNoCropResize'};
    n_db = length(db);
    
    classif = cell(length(db)*n_classif,3);
      
    for i = 1:n_db
        i0 = (i-1)*n_classif + 1;
        classif(i0:(i0+n_classif_BOF-1), 1) = classif_BOF;
        for j = i0:(i0+n_classif_BOF-1)
            classif{j, 2} = db{i};
            classif{j, 3} = sprintf('%s_test_SVM',db{i});
        end
        
        
        i0 = (i-1)*n_classif + n_classif_BOF + 1;
        classif(i0:(i0+n_classif_PYR-1), 1) = classif_PYR;
        for j = i0:(i0+n_classif_BOF-1)
            classif{j, 2} = db{i};
            classif{j, 3} = sprintf('%s_test_SVM',db{i});
        end
    end
    
    if(use_cluster)
        run_in_parallel('evaluate_parallel',[],classif,[],7000);
    else
        for i = 1:size(classif,1)
            evaluate(classif{i,1}, classif{i,2}, classif{i,3});
        end
    end
end