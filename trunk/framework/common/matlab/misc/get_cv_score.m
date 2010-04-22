function cv_score = get_cv_score(root, dir)
    file = fullfile(root, dir, 'cross_validation.txt');
    
    cv_score = load(file', '-ascii');
    while ~isscalar(cv_score)
        cv_score = max(cv_score);
    end
end

