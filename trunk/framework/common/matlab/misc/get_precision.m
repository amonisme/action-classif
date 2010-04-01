function precision = get_precision(classes, correct_label, score)
    n_classes = size(classes, 1);
    precision = size(n_classes, 1);
    
    for i=1:n_classes
        [rec,prec,ap,sortind] = precisionrecall(score(:, i), correct_label == i);
        precision(i) = ap*100;
    end
    
    precision = mean(precision);    
end

