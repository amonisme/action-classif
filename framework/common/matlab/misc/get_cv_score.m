function [cv_score cv_stdev] = get_cv_score(root, d)
    file = fullfile(root, d, 'cross_validation.txt');
    cv_score = load(file, '-ascii');
    
    try
        file = fullfile(root, d, 'cv_std_deviation.txt');
        cv_stdev = load(file, '-ascii');
    catch ME
        cv_stdev = zeros(size(cv_score));
    end
    
    cv_score = reshape(cv_score, numel(cv_score), 1);
    cv_stdev = reshape(cv_stdev, numel(cv_stdev), 1);
    
    i = floor(median(find(cv_score == max(cv_score))));
    
    cv_score = cv_score(i);
    cv_stdev = cv_stdev(i);
end

