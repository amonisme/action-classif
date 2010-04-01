function res = run_in_parallel_local(fun, common_args, parallel_args, num_instances, debug, pg, pg_offset, pg_scale)
    % Given a function name 'fun' and 'n' instances (each instance is
    % reprented by a line of 'args' (might be a cell or an array)), 'run_in_parallel' calls
    % 'num_instances' Matlab clients to run 'fun' in parallel over subpart
    % of 'args' of size: size(args,1)/num_instances
	global TEMP_DIR;

    if nargin < 4 || num_instances == 0
        num_instances = maxNumCompThreads;
    end
    if nargin < 5
        debug = 0;
    end
    pg_enabled = nargin >= 6 && isa(pg, 'ProgressBar');
    if nargin < 7
        pg_offset = 0;
    end
    if nargin < 8
        pg_scale = 1;
    end       
    
    if debug == 1
        num_instances = 1;
    end 
    tid = open_parallel_task(num_instances);
    
    size_args = ceil(size(parallel_args,1)/num_instances);
    
    save_file('args', tid, 0, common_args);
    
    for i = 1:num_instances
        if i == num_instances
            index = ((i-1)*size_args+1) : size(parallel_args,1);
        else
            index = ((i-1)*size_args+1) : i*size_args;
        end
        
        if ~isempty(index)
            subargs = cat(1,parallel_args(index, :));
            save_file('args', tid, i, subargs);
            run_matlab_instance(tid, i, fun, debug);
        else
            num_instances = i-1;
            break;
        end            
    end
    
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
end

function stopTimer(obj, event)
    stop(obj)
end

