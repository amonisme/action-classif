function basis_scores = compute_parallel_basis_feat_score(common, basis_feat)
    tid = task_open();

    n_basis_features = size(basis_feat, 1);
    basis_scores = zeros(n_basis_features, common.n_classes,2);                    
    support = zeros(n_basis_features, common.n_classes);

    for i = 1:common.n_classes
        I = find(common.ids == i);
        s = zeros(1, n_basis_features);
        for j = 1:length(I)
            for k = 1:n_basis_features
                J = (common.assign{I(j)} == k);
                if ~isempty(find(J,1))
                    s(k) = s(k) + max(common.descr{I(j)}(J,:) * basis_feat(k,:)');
                end
            end
        end
        support(:, i) = s' / length(I);
    end

    for i = 1:common.n_classes
        basis_scores(:,i,1) = support(:, i); 
        basis_scores(:,i,2) = support(:, i) ./ max(support(:,(1:common.n_classes)~=i), [], 2);
    end
    
    task_close(tid);
end

