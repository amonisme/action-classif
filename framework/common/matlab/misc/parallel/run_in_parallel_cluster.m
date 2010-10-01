function res = run_in_parallel_cluster(fun, common_args, parallel_args, memory, pg, pg_offset, pg_scale)
    % Given a function name 'fun' and 'n' instances (each instance is
    % reprented by a line of 'args' (might be a cell or an array)), 'run_in_parallel_cluster' calls
    % 'n' Matlab clients to run 'fun' in parallel over the cluster
    global CLUSTER_WORKING_DIR CLUSTER_USER TEMP_DIR HASH_PATH;
          
    if memory <= 0
        memory = 2048;
    end
    memory = sprintf('%dmb', memory);
        
    
    pg_enabled = nargin >= 5 && isa(pg, 'ProgressBar');
    
    num_instances = size(parallel_args, 1);
    
    tid = open_parallel_task(num_instances);
 
    save_file('args', tid, 0, common_args);
    
    if isempty(HASH_PATH)
        HASH_PATH = '0';
    end
    M = cell(num_instances, 4);   
    for i = 1:num_instances
        save_file('args', tid, i, parallel_args(i, :));
        M{i,1} = tid;
        M{i,2} = i;
        M{i,3} = HASH_PATH;
        M{i,4} = fun;     
    end
    
    % Run on cluster
    compileAndRunForCluster('cluster.m',CLUSTER_USER,CLUSTER_WORKING_DIR,M,memory)
    
    % Wait all tasks finishes.
    average_comp_time = Inf;
    offset_wait = num_instances:-1:1;
    num_waiting = num_instances;
    waiting = ones(1, num_instances);
    progress = zeros(num_instances, 1);
    res = cell(num_instances, 1);
    files = cell(num_instances, 2);
    for i = 1:num_instances
        files{i,1} = fullfile(TEMP_DIR, tid, sprintf('res%d.mat', i));
        files{i,2} = fullfile(TEMP_DIR, tid, sprintf('info.%d', i));
    end
    
    tic;
    while num_waiting > 0
        pgr = 0;
        no_finish = 1;
        for i = 1:num_instances
            if waiting(i) == 0
                pgr = pgr + 1/num_instances;
            elseif exist(files{i,1}, 'file') == 2                
                load(files{i,1}, 'args', 't');
                res{i} = args;
                num_waiting = num_waiting - 1;
                waiting(i) = 0;
                pgr = pgr + 1/num_instances;
                no_finish = 0;
                if isinf(average_comp_time)
                    average_comp_time = t;
                else
                    average_comp_time = average_comp_time + (t - average_comp_time) / (num_instances-num_waiting);                
                end
            elseif pg_enabled && exist(files{i,2}, 'file') == 2
                fid = fopen(files{i,2},'r');
                p = fread(fid, 1, 'float32');
                fclose(fid);
                if isempty(p)
                    pgr = pgr + progress(i)/num_instances;
                else
                    pgr = pgr + p/num_instances;
                    progress(i) = p;
                end                
            end
        end
        
        if pg_enabled
            pg.progress(pg_offset + pg_scale * pgr);
        end

        if no_finish
            late_task = waiting & ((toc - offset_wait) > 2*average_comp_time);
            if ~isempty(find(late_task,1))
                M2 = M(late_task,:);            
                compileAndRunForCluster('cluster.m',CLUSTER_USER,CLUSTER_WORKING_DIR,M2,memory);            
                tic;
                I = find(late_task)';
                n = length(I);
                for i = I
                    offset_wait(i) = 60 + n;
                    n = n - 1;
                end
            end
        end
        
        if 1
            num = find(waiting);
            if length(num)<=3 && num_waiting>0
                if length(num) == 3
                    fprintf('Waiting for threads #%d, #%d and #%d\n',num(1),num(2),num(3));
                elseif length(num) == 2
                    fprintf('Waiting for threads #%d and #%d\n',num(1),num(2));
                elseif length(num) == 1
                    fprintf('Waiting for thread #%d\n',num(1));
                end                    
            else                
                fprintf('Waiting for %d threads to finish...\n', num_waiting);
            end
                        
        end
        pause(1);
    end
    res = cat(1,res{:});
    
    close_parallel_task(tid);
end

