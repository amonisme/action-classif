function [perf labels legd] = BMVC_compute_mean_perf()
    d = {'DataBaseCropped_test_SVM', ...
         'DataBaseNoCrop_test_SVM', ...
         'DataBaseNoCropResize_test_SVM', ...
         'DataBaseNoCropResize_test_SVM_CV', ...
         'DataBaseNoCropResize_test_SVM_FullGrid', ...         
         'DataBaseNoCropResize_test_SVM_Concat', ...
         'DBGupta_test_SVM', ...
         'DBGuptaResize_test_SVM'};
       
    perf = zeros(40,1);
    labels = cell(40,1);
    legd = cell(8,1);
    
    for i=1:length(d)
        concatenate = strcmp(d{i}, 'DataBaseNoCropResize_test_SVM_Concat');     
        full_grid = strcmp(d{i}, 'DataBaseNoCropResize_test_SVM_FullGrid');     
        no_cv = strcmp(d{i}, 'DataBaseNoCropResize_test_SVM');
        test_C = concatenate || full_grid || no_cv || strcmp(d{i}, 'DataBaseNoCropResize_test_SVM_CV');
        [classif_BOF_A_B classif_PYR_A_B] = get_paper_BMVC_classif([], [], 0, no_cv, concatenate, full_grid);
        [classif_BOF_C classif_PYR_C] = get_paper_BMVC_classif([], [], 1, no_cv, concatenate, full_grid);
        
        if test_C
            classif = [classif_BOF_C; classif_PYR_C];
        else
            classif = [classif_BOF_A_B; classif_PYR_A_B];
        end
        
        for j = 1:40
            p = get_prec_acc(fullfile('/data/vdelaitr/', d{i}), classif{j}.toFileName());
            perf(j) = perf(j) + p;
        end
    end
    
    perf = perf / length(d);
    
    sizes = [256 512 1024 2048 4096];
    kerns = {'Linear' 'RBF' 'Intersection' 'Chi2'};
    
    for i = 1:length(kerns)
        legd{i} = sprintf('%s BOF', kerns{i});
        for j = 1:length(sizes)
            labels{(i-1)*length(sizes)+j} = sprintf('%s %d', legd{i}, sizes(j));
            fprintf('%s: %0.2f%%\n', labels{(i-1)*length(sizes)+j}, perf((i-1)*length(sizes)+j));
        end
    end
    for i = 1:length(kerns)
        legd{i+4} = sprintf('%s PYR', kerns{i});
        for j = 1:length(sizes)
            labels{20+(i-1)*length(sizes)+j} = sprintf('%s %d', legd{i+4}, sizes(j));
            fprintf('%s: %0.2f%%\n', labels{20+(i-1)*length(sizes)+j}, perf(20+(i-1)*length(sizes)+j));
        end
    end    
    
    p = reshape(perf, 5, 8);
    p = p(:,8:-1:1);
    l = legd(8:-1:1);
    plot(p, 'DisplayName', 'p', 'YDataSource', 'p'); figure(gcf);
    legend(l, 'Location', 'EastOutside');
end