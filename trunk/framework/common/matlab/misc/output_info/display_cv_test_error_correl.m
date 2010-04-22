function [err_cv err_prec] = display_cv_test_error_correl(prec_cv, prec_test, names, dim, display_graph)
    if nargin < 3
        display_graph = 0;
    end
 
    err_cv = compare_get_dim(prec_cv, dim);
    for i=1:size(err_cv,1)
        err_cv{i} = 100 - err_cv{i};
    end
    err_prec = compare_get_dim(prec_test, dim);
    for i=1:size(err_prec,1)
        err_prec{i} = 100 - err_prec{i};
    end        
    
    if display_graph
        if dim
            legends = keys(names{dim});
        else
            legends = {};
        end
        display_plots(err_cv, err_prec, 'Validation error (in %)', 'Test error (in %)', 'Validation/Test error correlation', legends, 1);
    end 
end