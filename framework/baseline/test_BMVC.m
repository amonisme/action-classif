function classif = test_BMVC(db_id, use_cluster, dont_run)
    global USE_PARALLEL SHOW_BAR;
    USE_PARALLEL = 1;
    SHOW_BAR = 1;
    
    if nargin < 2
        use_cluster = 0;
    end      
    if nargin < 3
        dont_run = 0;
    end       
    
    db = {'../../DataBaseCropped', ...
          '../../DataBaseNoCrop', ...
          '../../DataBaseNoCropResize', ...
          '../../DataBaseNoCropResize_CV', ...
          '../../DataBaseNoCropResize_FullGrid', ...
          '../../DataBaseNoCropResize_Concat', ...
          '../../DBGupta', ...
          '../../DBGuptaResize'};      
    dir = {'../../DataBaseCropped_test_SVM', ...
           '../../DataBaseNoCrop_test_SVM', ...
           '../../DataBaseNoCropResize_test_SVM', ...
           '../../DataBaseNoCropResize_test_SVM_CV', ...
           '../../DataBaseNoCropResize_test_SVM_FullGrid', ...         
           '../../DataBaseNoCropResize_test_SVM_Concat', ...
           '../../DBGupta_test_SVM', ...
           '../../DBGuptaResize_test_SVM'};
       
    concatenate = strcmp(db{db_id}, '../../DataBaseNoCropResize_Concat');       
      
    [classif_BOF_A_B classif_PYR_A_B] = get_paper_BMVC_classif([], [], 0, concatenate);
    [classif_BOF_C classif_PYR_C] = get_paper_BMVC_classif([], [], 1, concatenate);
    n_classif_BOF_A_B = length(classif_BOF_A_B);
    n_classif_PYR_A_B = length(classif_PYR_A_B);
    n_classif_BOF_C = length(classif_BOF_C);
    n_classif_PYR_C = length(classif_PYR_C);    
       
    if ~isempty(find(strcmp(db{db_id}, {'../../DataBaseNoCropResize' '../../DataBaseNoCropResize_CV' '../../DataBaseNoCropResize_FullGrid' '../../DataBaseNoCropResize_Concat'}),1))
        n_classif = n_classif_BOF_C + n_classif_PYR_C;
        test_C = 1;
    else
        test_C = 0;
        n_classif = n_classif_BOF_A_B + n_classif_PYR_A_B;
    end
    
    fprintf('Dir: %s\nTest_C: %d\nConcat: %d\n', dir{db_id}, test_C, concatenate);
    
    classif = cell(n_classif,3);
      
    if ~isempty(find(strcmp(db{db_id}, {'../../DataBaseNoCropResize' '../../DataBaseNoCropResize_CV' '../../DataBaseNoCropResize_FullGrid' '../../DataBaseNoCropResize_Concat'}),1))
        classif(1:n_classif_BOF_C, 1) = classif_BOF_C;
        for j = 1:n_classif_BOF_C
            classif{j, 2} = db{db_id};
            classif{j, 3} = dir{db_id};
        end        
    else
        classif(1:n_classif_BOF_A_B, 1) = classif_BOF_A_B;
        for j = 1:n_classif_BOF_A_B
            classif{j, 2} = db{db_id};
            classif{j, 3} = dir{db_id};
        end        
    end

    if ~isempty(find(strcmp(db{db_id}, {'../../DataBaseNoCropResize' '../../DataBaseNoCropResize_CV' '../../DataBaseNoCropResize_FullGrid' '../../DataBaseNoCropResize_Concat'}),1))
        classif((n_classif_BOF_C+1):(n_classif_BOF_C+n_classif_PYR_C), 1) = classif_PYR_C;
        for j = (n_classif_BOF_C+1):(n_classif_BOF_C+n_classif_PYR_C)
            classif{j, 2} = db{db_id};
            classif{j, 3} = dir{db_id};
        end        
    else
        classif((n_classif_BOF_A_B+1):(n_classif_BOF_A_B+n_classif_PYR_A_B), 1) = classif_PYR_A_B;
        for j = (n_classif_BOF_A_B+1):(n_classif_BOF_A_B+n_classif_PYR_A_B)
            classif{j, 2} = db{db_id};
            classif{j, 3} = dir{db_id};
        end        
    end                

    
    if ~dont_run
        if(use_cluster)
            run_in_parallel('evaluate_parallel',[],classif,[],2048);
        else
            for i = 1:size(classif,1)
                evaluate(classif{i,1}, classif{i,2}, classif{i,3});
            end
        end
    end
end