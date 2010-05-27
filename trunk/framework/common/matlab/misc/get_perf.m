function [prec acc] = get_perf(label, score, correct_label)
    n_classes = max(correct_label);
    
    acc = zeros(n_classes,1);
    prec = zeros(n_classes,1);
    for i=1:size(score,1)
        if label(i) == correct_label(i)
            acc(label(i)) = acc(label(i)) + 1;
        end
    end
    
    for i = 1:n_classes
        acc(i) = acc(i) * 100 / length(find(correct_label == i));        
        [r1,r2,ap] = precisionrecall(score(:, i), correct_label == i);
        prec(i) = ap * 100;   
    end
    
    acc = mean(acc);
    prec = mean(prec); 
end

