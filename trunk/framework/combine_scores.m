function [scores, X1, X2] = combine_scores(root_classif1, root_classif2, DB1, DB2)
    global OUTPUT_LOG;
    OUTPUT_LOG = 0;
    
    load(fullfile(root_classif1,'classifier.mat'));
    classif1 = classifier;
    
    load(fullfile(root_classif2,'classifier.mat'));
    classif2 = classifier;
          
    [Ipaths classes subclasses map_sub2sup correct_label assigned_label score] = classif1.classify(sprintf('%s.train.mat', DB1));    
    X1 = normalize_scores(score, correct_label);
    
    [Ipaths classes subclasses map_sub2sup correct_label assigned_label score] = classif2.classify(sprintf('%s.train.mat', DB2));        
    X2 = normalize_scores(score, correct_label);
    
    load(fullfile(root_classif1,'result.mat'));
    scores1 = (1 + exp(-[scores ones(size(scores,1), 1)] * X1)) .^ -1;  
    
    load(fullfile(root_classif2,'result.mat'));
    scores2 = (1 + exp(-[scores ones(size(scores,1), 1)] * X2)) .^ -1;
    
    scores = scores1 + scores2;
end