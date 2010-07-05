function weights  = normalize_scores(scores, labels)
    n_classes = size(scores, 2);
    weights = zeros(n_classes+1,n_classes);
    
    s = [scores ones(size(scores,1),1)];
    for i=1:n_classes
        weights(:,i) = logistic(s, labels == i);
    end
end

