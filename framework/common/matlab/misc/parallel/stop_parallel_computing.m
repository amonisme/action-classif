function stop_parallel_computing()
	global TEMP_DIR;
    files = dir(TEMP_DIR);
    d = {files([files(:).isdir] & not(strcmp({files(:).name},'.') | strcmp({files(:).name},'..'))).name}';
    
    for i=1:size(d,1)
        rmdir(fullfile(TEMP_DIR,d{i}),'s')
    end
end

