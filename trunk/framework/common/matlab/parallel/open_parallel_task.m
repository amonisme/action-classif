function tid = open_parallel_task(n)
	global TEMP_DIR;
    if ~isdir(TEMP_DIR)
        mkdir(TEMP_DIR);
    end
    
    tid = generate_key();
    while isdir(fullfile(TEMP_DIR,tid))
        tid = generate_key();
    end
    mkdir(fullfile(TEMP_DIR,tid));
    for i=1:n
        mkdir(fullfile(TEMP_DIR,tid,num2str(i)));
    end
end

