  function [accuracy precision] = display_results(dir, fig, root)
    if nargin < 2
        fig = 0;
    end
    if nargin < 3
        root = 'experiments';
    end

    load(fullfile(root,dir,'results.mat'));
    
    % Backward compatibility
    if exist('map_sub2sup', 'var') ~= 1
        n_img = length(assigned_label);
        assigned = zeros(n_img, length(classes));
        correct = zeros(n_img, length(classes));        
        for i=1:n_img
            assigned(i, assigned_label(i)) = 1;
            correct(i, assigned_label(i)) = 1;            
        end
        assigned_action = assigned;
        correct_label = correct;        
        subclasse = 0;
    else
        subclasse = ~isempty(map_sub2sup);
    end
    
    if subclasse       
      fprintf('Results for subclasses:\n');    
    end
    correct_labels = cat(1, images(:).actions);
    table = confusion_table(correct_labels,assigned_action);  
    accuracy = display_multiclass_accuracy(subclasses, table);
    precision = display_precision_recall(subclasses, correct_labels, score);     
        
    if subclasse
        fprintf('Results for classes:\n');
        [new_score new_correct_action new_assigned_action] = convert2supclasses(map_sub2sup, score, correct_labels, assigned_action);
        new_table = confusion_table(new_correct_action, new_assigned_action);  
        accuracy = display_multiclass_accuracy(classes, new_table);
        precision = display_precision_recall(classes, new_correct_action, new_score); 
    end
    
    file = fullfile(root, dir, 'cross_validation.txt');
    if exist(file, 'file') == 2
        load(file, 'cross_validation', '-ascii');

        dim = find(size(cross_validation)>1);
        if dim > 0
            if fig       
                if length(dim) == 1
                    figure('Name','Cross-validation results');
                    plot(cross_validation);
                elseif  length(dim) == 2
                    figure('Name','Cross-validation results');
                    surf(cross_validation);
                else
                    fprintf('Too many parameters to plot cross-validation results!\n');
                end
            end
            cross_validation            
        end
    end
end

