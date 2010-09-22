function close_parallel_task(tid)
	global TEMP_DIR;
    try
        rmdir(fullfile(TEMP_DIR,tid),'s')
    catch ME
    end
end

