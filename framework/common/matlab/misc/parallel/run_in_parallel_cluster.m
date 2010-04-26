function res = run_in_parallel_cluster(fun, common_args, parallel_args, memory, pg, pg_offset, pg_scale)
    % Given a function name 'fun' and 'n' instances (each instance is
    % reprented by a line of 'args' (might be a cell or an array)), 'run_in_parallel_cluster' calls
    % 'n' Matlab clients to run 'fun' in parallel over the cluster
    global CLUSTER_WORKING_DIR CLUSTER_USER TEMP_DIR HASH_PATH;
        
    current_dir = cd;
    current_temp = TEMP_DIR;
    TEMP_DIR = '../../temp';
    cd(CLUSTER_WORKING_DIR);
    
    if memory == 0
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
    compileAndRunForCluster('run_instance_on_cluster.m',CLUSTER_USER,CLUSTER_WORKING_DIR,M,memory)
    
    % Wait all tasks finishes.
    num_waiting = num_instances;
    waiting = ones(num_instances, 1);
    progress = zeros(num_instances, 1);
    res = cell(num_instances, 1);
    files = cell(num_instances, 2);
    for i = 1:num_instances
        files{i,1} = fullfile(TEMP_DIR, tid, sprintf('res%d.mat', i));
        files{i,2} = fullfile(TEMP_DIR, tid, sprintf('info.%d', i));
    end
    
    while num_waiting > 0
        pgr = 0;
        for i = 1:num_instances
            if waiting(i) == 0
                pgr = pgr + 1/num_instances;
            elseif exist(files{i,1}, 'file') == 2
                load(files{i,1}, 'args');
                res{i} = args;
                num_waiting = num_waiting - 1;
                waiting(i) = 0;
                pgr = pgr + 1/num_instances;
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
        
        t = timer('StartDelay', 1, 'TimerFcn', @stopTimer);
        start(t);
        wait(t);
    end
    res = cat(1,res{:});
    
    close_parallel_task(tid);
    cd(current_dir);
    TEMP_DIR = current_temp;
end

function stopTimer(obj, event)
    stop(obj)
end

