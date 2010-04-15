function print_parameters_names(names)
    fprintf('\nPossible detectors:\n');
    print_values(names{1});
    fprintf('\nPossible descriptors:\n');
    print_values(names{2});
    fprintf('\nPossible signatures:\n');
    print_values(names{3});
    fprintf('\nPossible signature''s norms:\n');
    print_values(names{4});
    fprintf('\nPossible classifiers:\n');
    print_values(names{5});
end

function print_values(map)
    n = keys(map);
    v = values(map);
    [v, I] = sort([v{:}]);
    n = n(I);
    for i = 1:length(n)
        fprintf('%d - %s\n', v(i), n{i});
    end
end