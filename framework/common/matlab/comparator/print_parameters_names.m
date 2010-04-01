function print_parameters_names(names)
    fprintf('\nPossible detectors:\n');
    print_values(names.detector);
    fprintf('\nPossible descriptors:\n');
    print_values(names.descriptor);
    fprintf('\nPossible signatures:\n');
    print_values(names.signature);
    fprintf('\nPossible signature''s norms:\n');
    print_values(names.signorm);
    fprintf('\nPossible classifiers:\n');
    print_values(names.classifier);
end

function print_values(map)
    n = keys(map);
    v = values(map);
    for i = 1:length(n)
        fprintf('%d - %s\n', v{i}, n{i});
    end
end