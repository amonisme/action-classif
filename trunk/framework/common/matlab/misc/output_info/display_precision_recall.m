function precision = display_precision_recall(classes, correct_label, score, fig)
    if nargin<4 
        fig=0; 
    end

    n_classes = size(classes, 1);
    precision = size(n_classes, 1);
    
    for i=1:n_classes
        [rec,prec,ap] = precisionrecall(score(:, i), correct_label == i);
        ap = ap*100;
        
        if fig
            % plot precision/recall
            name = sprintf('Action ''%s''',classes{i});
            figure('Name', name);
            plot(rec,prec,'-');
            grid;
            xlabel 'recall'
            ylabel 'precision'

            title(sprintf('%s - AP = %.3f',name, ap));
            axis([0 1 0 1])
        end
        
        precision(i) = ap;
    end
    
    precision = mean(precision);    
    
    write_log(sprintf('Precision-recall average precision: %.2f\n', precision));
end

