function [accuracy precision] = display_results(dir, fig, root)
    if nargin < 2
        fig = 0;
    end
    if nargin < 3
        root = 'experiments';
    end

    load(fullfile(root,dir,'results.mat'));
    
    accuracy = display_multiclass_accuracy(classes, confusion_table(correct_label,assigned_label));
    
    precision = display_precision_recall(classes, correct_label, score, fig);
    
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

