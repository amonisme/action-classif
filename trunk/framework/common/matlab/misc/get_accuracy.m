function [perf_total perf_classes table] = get_accuracy(table)
    n_classes = size(table, 1);

    nb_img = sum(table, 2);
    table = 100 * table ./ repmat(nb_img, 1, n_classes);
    
    perf_classes = diag(table);
    perf_classes = perf_classes(~isnan(perf_classes));
    perf_total = sum(perf_classes) / length(perf_classes);
end