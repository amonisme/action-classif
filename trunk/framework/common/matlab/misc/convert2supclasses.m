function [new_score new_correct_label new_assigned_label] = convert2supclasses(map, score, correct_label, assigned_label)
    if isempty(map)
        new_score = score;
        new_correct_label = correct_label;
        new_assigned_label = assigned_label;
    else        
        new_score = zeros(size(score, 1), max(map));
        new_correct_label  = zeros(size(score, 1), max(map));
        new_assigned_label = zeros(size(score, 1), max(map));
        
        for i=1:max(map)
            new_score(:,i) = max(score(:,map == i), [], 2);            
        end
        
        for i=1:length(map)
            new_correct_label(correct_label(i), map(i)) = 1;
            new_assigned_label(assigned_label(i), map(i)) = 1;
        end
    end
end