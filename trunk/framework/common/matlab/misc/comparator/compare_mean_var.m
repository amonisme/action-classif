function [m v] = compare_mean_var(tests_list)
    val = tests_list(tests_list ~= -1);
    m = mean(val);
    val = val - m;
    v = sqrt(sum(val .* val)/(length(val)-1+eps));     
end

