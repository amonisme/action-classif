function [status, result] = run_matlab_instance(tid, iid, hash, fun, debug)
    % Use -nodesktop instead -nojvm if you need to start the Java Virtual
    % Machine
    global TEMP_DIR LIB_DIR;
    if(strcmp(computer, 'PCWIN'))
        cmd = sprintf('matlab -nosplash -nodesktop -r "cd ''%s''; init_matlab(''%s'', ''%s'', %d, ''%s'', ''%s'', ''%s''); init_script(@%s);"', cd, fullfile(TEMP_DIR,tid,num2str(iid)), tid, iid, hash, TEMP_DIR, LIB_DIR, fun);
    else
        cmd = sprintf('/usr/matlab-2009a/bin/matlab -nosplash -nodesktop -r "cd ''%s''; init_matlab(''%s'', ''%s'', %d, ''%s'', ''%s'', ''%s''); init_script(@%s);"', cd, fullfile(TEMP_DIR,tid,num2str(iid)), tid, iid, hash, TEMP_DIR, LIB_DIR, fun);
    end
    
    if debug 
        system(cmd);
    else
        [status, result] = system([cmd ' &']);
    end
end

