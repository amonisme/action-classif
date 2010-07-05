function score = unit_feat_score(unit_feat, descr)   
    dsize = size(descr,2);
    d1_score = sum(descr .* repmat(unit_feat(1:dsize), size(descr,1), 1), 2);
    d2_score = sum(descr .* repmat(unit_feat((dsize+1):(2*dsize)), size(descr,1), 1), 2);    
 
    score = max(max(d1_score * d2_score'));
end