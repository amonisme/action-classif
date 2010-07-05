function scores = compute_parallel_model_score(common, models)
    tid = task_open();
    
    n_classes = size(models, 1);
    n_img = length(common.feat);    
    scores = zeros(n_classes,n_img);  

    for k = 1:n_classes
        n_unit_feat = length(models{k}.unit_feat);                
        sigs = zeros(n_unit_feat, n_img);

        % Computes signatures
        for i = 1:n_img
            task_progress(tid, (k-1+i/n_img)/n_classes);
            for j = 1:n_unit_feat                    
                sigs(j,i) = fit_unit_feat(common.feat{i}, common.descr{i}, common.bounding_boxes(i,:), models{k}.unit_feat(j));
            end
        end

        scores(k,:) = obj.models{k}.kernel.classify(obj.models{k}.svm, sigs)';
    end

    task_close(tid);
end

