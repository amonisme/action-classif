function compile_for_cluster(copy_src, copy_libs)
    global WORKING_ROOT CLUSTER_WORKING_DIR CLUSTER_USER;
    
    if nargin < 1
        copy_src = 1;
    end
    if nargin < 2
        copy_libs = 0;
    end    
    
    current_dir = cd;
    cd(WORKING_ROOT);

    [status,message,messageid] = mkdir(CLUSTER_WORKING_DIR);
    
    if copy_src
        target = fullfile(CLUSTER_WORKING_DIR, 'src');
        [s m] = system(sprintf('rm -rf %s', target));
        fprintf('Copy sources in %s...\n', target);
        copy_flatten_to(target, {'.m' ['.' mexext]});
    end
    if copy_libs
        target = fullfile(CLUSTER_WORKING_DIR, 'libs');
        [s m] = system(sprintf('rm -rf %s', target));
        fprintf('Copy libs in %s...\n', target);
        copy_same_to('common/libs', target, {'.mat' '' '.exe'});       
    end
    
    fprintf('Compile...\n');
    [s m] = system(sprintf('rm -rf %s', fullfile(CLUSTER_WORKING_DIR,'exec_cluster/cluster')));
    compileAndRunForCluster('cluster.m',CLUSTER_USER,CLUSTER_WORKING_DIR,{},'2048mb')
    
    cd(current_dir);
end

function copy_flatten_to(dest, ext_filter)
    d = paths();
    d = [d './'];
    n_dir = length(d);

    files = cell(n_dir, 2);

    for i = 1:n_dir
        f = dir(d{i});
        f = f(~[f(:).isdir]);

        I = zeros(length(f), 1);        
        for j = 1:length(f)
            if f(j).name(1) ~= '.'
                [directory filename ext]  = fileparts(f(j).name);
                I(j) = ~isempty(find(strcmp(ext, ext_filter), 1));
            end
        end
        f = f(logical(I));
        files{i,1} = {f(:).name}';
        files{i,2} = i*ones(length(files{i,1}), 1);
    end

    names = cat(1,files{:,1});
    dirs  = cat(1,files{:,2});

    for i = 1:length(names)-1
        j = find(strcmp(names{i}, names(i+1:end)), 1);
        if ~isempty(j)
            throw(MException('',sprintf('Duplicate name:\n%s\n%s\n',fullfile(d{dirs(i)}, names{i}), fullfile(d{dirs(j)}, names{i}))));
        end
    end
    
    [status,message,messageid] = mkdir(dest);
    for i = 1:length(names)
        system(sprintf('cp %s %s\n', fullfile(d{dirs(i)}, names{i}), dest));
    end
end

function not_empty = copy_same_to(src, dest, ext_filter)
    not_empty = 0;
    f = dir(src);
        
    for i = 1:length(f)
        if f(i).name(1)~='.' && isdir(fullfile(src, f(i).name))
            dir_dest = fullfile(dest, f(i).name);
            [status,message,messageid] = mkdir(dir_dest);
            if copy_same_to(fullfile(src, f(i).name), fullfile(dest, f(i).name), ext_filter)
                not_empty = 1;
            else
                rmdir(dir_dest);
            end
        else
            [directory filename ext]  = fileparts(f(i).name);
            if ~isempty(find(strcmp(ext, ext_filter), 1))
                not_empty = 1;
                system(sprintf('cp %s %s\n', fullfile(src, f(i).name), dest));
            end
        end
    end
end
