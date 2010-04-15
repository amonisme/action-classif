function args = load_file(file, tid, iid)
	global TEMP_DIR;
    load(fullfile(TEMP_DIR,tid,sprintf('%s_%d.mat',file,iid)), 'args');
end
