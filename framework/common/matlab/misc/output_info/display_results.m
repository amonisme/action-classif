  function [accuracy precision] = display_results(dir, fig, root)
    if nargin < 2
        fig = 0;
    end
    if nargin < 3
        root = 'experiments';
    end

    load(fullfile(root,dir,'results.mat'));
    
    % Output results
    if ~isempty(map_sub2sup)        
        fprintf('Results for subclasses:\n');    
    end
    correct_labels = cat(1, images(:).actions);
    table = confusion_table(correct_labels,assigned_action);  
    accuracy = display_multiclass_accuracy(subclasses, table);
    precision = display_precision_recall(subclasses, correct_labels, score); 
    
    if ~isempty(map_sub2sup)
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

