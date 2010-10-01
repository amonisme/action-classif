function [scores, X1, X2, scores1, scores2] = combine_scores(root_classif1, root_classif2, DB1, DB2)
    global OUTPUT_LOG;
    OUTPUT_LOG = 0;
    
    load(fullfile(root_classif1,'classifier.mat'));
    classif1 = classifier;
    
    load(fullfile(root_classif2,'classifier.mat'));
    classif2 = classifier;
    
    file = sprintf('scores_%s.mat', classif1.toFileName());
    if exist(file,'file') == 2
        load(file);
        fprintf('Scores loaded from %s.\n', file);
    else
        [images classes subclasses map_sub2sup assigned_action score] = classif1.classify(sprintf('%s.train.mat', DB1));
        save(file,'images','classes','subclasses','map_sub2sup','assigned_action','score');
    end    
    score(isinf(score)) = min(min(score(~isinf(score))));
    X1 = normalize_scores(score, cat(1,images(:).actions));
    
    file = sprintf('scores_%s.mat', classif2.toFileName());
    if exist(file,'file') == 2
        load(file);
        fprintf('Scores loaded from %s.\n', file);
    else        
        [images classes subclasses map_sub2sup assigned_action score] = classif2.classify(sprintf('%s.train.mat', DB2));        
        save(file,'images','classes','subclasses','map_sub2sup','assigned_action','score');
    end
    score(isinf(score)) = min(min(score(~isinf(score))));
    X2 = normalize_scores(score, cat(1,images(:).actions));
    
    file = fullfile(root_classif1,'results.mat');
    load(file);
    fprintf('Results loaded from %s.\n', file);
    score(isinf(score)) = min(min(score(~isinf(score))));
    scores1 = [score ones(size(score,1), 1)] * X1;  
    
    file = fullfile(root_classif2,'results.mat');
    load(file);
    fprintf('Results loaded from %s.\n', file);
    score(isinf(score)) = min(min(score(~isinf(score))));
    scores2 = [score ones(size(score,1), 1)] * X2;
    
    scores = scores1 + scores2;
end