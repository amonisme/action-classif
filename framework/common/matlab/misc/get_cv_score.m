function [cv_score cv_stdev] = get_cv_score(root, d)
    file = fullfile(root, d, 'cv_log.mat');
    load(file, 'cv_res', 'cv_dev');

    cv_score = reshape(cv_res, numel(cv_res), 1);
    cv_stdev = reshape(cv_dev, numel(cv_dev), 1);
    
    i = floor(median(find(cv_score == max(cv_score))));
    
    if ~isnan(i)
        cv_score = cv_score(i);
        cv_stdev = cv_stdev(i);
    else
        cv_score = 0;
        cv_stdev = -1;
    end
end

