function res = run_in_parallel(fun, common_args, parallel_args, num_instances, memory, pg, pg_offset, pg_scale)
    % Given a function name 'fun' and 'n' instances (each instance is
    % reprented by a line of 'args' (might be a cell or an array)), 'run_in_parallel' calls
    % 'num_instances' Matlab clients to run 'fun' in parallel over subpart
    % of 'args' of size: size(args,1)/num_instances
    
    global USE_CLUSTER;
    
    if USE_CLUSTER || isempty(num_instances)
        if nargin < 8
            res = run_in_parallel_cluster(fun, common_args, parallel_args, memory);
        else
            res = run_in_parallel_cluster(fun, common_args, parallel_args, memory, pg, pg_offset, pg_scale);
        end
    else
        if nargin < 8
            res = run_in_parallel_local(fun, common_args, parallel_args, num_instances, memory);
        else
            res = run_in_parallel_local(fun, common_args, parallel_args, num_instances, memory, pg, pg_offset, pg_scale);
        end        
    end
end
