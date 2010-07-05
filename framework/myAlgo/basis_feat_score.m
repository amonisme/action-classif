function score = basis_feat_score(basis_feat, descr, n_classes, ids)
    n_img = length(ids);
    
    basis_descr = basis_feat(1:128);
    score = max(descr * basis_descr');
end