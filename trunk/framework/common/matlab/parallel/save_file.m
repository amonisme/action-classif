function save_file(file, tid, iid, args)
	global TEMP_DIR;
    save(fullfile(TEMP_DIR,tid,sprintf('%s_%d.mat',file,iid)), 'args');
end
