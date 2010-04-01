function [status, result] = run_matlab_instance(tid, iid, fun, debug)
    % Use -nodesktop instead -nojvm if you need to start the Java Virtual
    % Machine
    global TEMP_DIR;
    cmd = sprintf('/usr/matlab-2009a/bin/matlab -nosplash -nodesktop -r "cd ''%s''; init_matlab(''%s'', ''%s'', %d); init_script(@%s);"', cd, fullfile(TEMP_DIR,tid,num2str(iid)), tid, iid, fun);
    
    if debug 
        system(cmd);
    else
        [status, result] = system([cmd ' &']);
    end
end

