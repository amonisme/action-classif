function compare_results(precision, accuracy)
    [mp vp] = compare_mean_var(precision);    
    fprintf('Precision: %.1f ± %.1f\n', mp, vp);
    
    if nargin >= 2 
        [mv vv] = compare_mean_var(accuracy);
        fprintf('Accuracy : %.1f ± %.1f\n', mv, vv);
    end
end

