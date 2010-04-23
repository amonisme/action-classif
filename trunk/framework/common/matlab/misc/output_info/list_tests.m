function [perf d] = list_tests(root, do_print)
    if nargin < 1
        root = 'experiments';
    end
    if nargin < 2
        do_print = 1;
    end
    
    files = dir(root);
    directories = {files([files(:).isdir] & not(strcmp({files(:).name},'.') | strcmp({files(:).name},'..'))).name}';
    
    perf = zeros(size(directories,1), 2);
    d = cell(size(directories,1), 1);
    n_dir = size(directories, 1);
    current = 0;
    
    pg = ProgressBar('Listing results','Extracting performances...');
    for i = 1:n_dir
        pg.progress(i/n_dir);
        
        [p a] = get_prec_acc(root, directories{i});
        if ~isempty(p) && ~isempty(a)
            current = current + 1;
            perf(current,1) = p;
            perf(current,2) = a;
            d{current} = directories{i};
        end
    end
    pg.close();
    d = {d{1:current,1}};
    perf = perf(1:current,:);
    [perf I] = sortrows(perf,[-1 -2]);
    d = d(I);

    if do_print
        for i = 1:current
            fprintf('P/A: %.2f / %.2f - %s\n', perf(i,1), perf(i,2), d{i});
        end    
    end
end

