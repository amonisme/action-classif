function perf_total = display_multiclass_accuracy(classes, table)
    n_classes = size(table, 1);
    
    [perf_total perf_classes table] = get_accuracy(table);

    write_log('Confusion Table:\n');
 
    for i=1:n_classes
        for j=1:n_classes
            write_log(sprintf('%.2f ', table(i,j)));
            if j == n_classes
                write_log('\\\\\n');
            else
                write_log('& ');
            end
        end
    end
    
    write_log('\nPerformances:\n');
    for i=1:n_classes
        write_log(sprintf('%s: %.2f\n', classes{i}, perf_classes(i)));
    end
    write_log(sprintf('-------\nMulti-class accuracy: %.2f\n', perf_total));
    
   
end

