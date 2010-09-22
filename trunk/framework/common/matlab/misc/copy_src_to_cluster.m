function copy_src_to_cluster(copy_libs)
    global CLUSTER_WORKING_DIR;
    
    if strcmp(CLUSTER_WORKING_DIR, fullfile('/nfs/', cd))
        fprintf('You are already in the cluster directory!!\n');
    else       
    
        if nargin < 1
            copy_libs = 0;
        end

        d = paths();
        d = [d './'];
        n_dir = length(d);

        files = cell(n_dir, 2);

        for i = 1:n_dir
            f = dir(d{i});
            f = f(~[f(:).isdir]);

            I = zeros(length(f), 1);        
            for j = 1:length(f)
                [directory filename ext]  = fileparts(f(j).name);
                I(j) = isempty(find(strcmp(ext, {'' '.m~' '.c' '.c~' '.cpp' '.cpp~' '.h' '.h~' '.jpg' '.zip' '.cc' '.cc~' '.mat' '.tc' '.tc~' '.txt' '.txt~' '.log' '.log~' '.asv' '.htm' '.html' '' '.py' '.pdf'}), 1));
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

        [status,message,messageid] = mkdir(CLUSTER_WORKING_DIR);
        for i = 1:length(names)
            system(sprintf('cp %s %s\n', fullfile(d{dirs(i)}, names{i}), CLUSTER_WORKING_DIR));
        end

        if copy_libs
            system(sprintf('cp -Rf common/libs %s\n', fullfile(CLUSTER_WORKING_DIR,'..','libs')));
        end
    end
end

