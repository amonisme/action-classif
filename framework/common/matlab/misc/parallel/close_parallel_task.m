function close_parallel_task(tid)
	global TEMP_DIR;
    rmdir(fullfile(TEMP_DIR,tid),'s')
end

