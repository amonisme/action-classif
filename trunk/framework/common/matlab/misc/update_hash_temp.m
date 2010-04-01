function update_hash_temp(hash_src, hash_target)
    global SHOW_BAR;
    SHOW_BAR = 1;
  
  	global TEMP_DIR;
    root = TEMP_DIR;
    files = dir(root);
    files = {files(~[files(:).isdir]).name}';
    
    hash_target = num2str(hash_target);
        
    pg = ProgressBar('',sprintf('Changing hash codes of directory: %s', root));
    for i = 1:size(files, 1)
        pg.progress(i/size(files, 1));
        
        f = files{i};
        index = regexp(f, '_');
        
        if ~isempty(index)
            index = index(1);
            hash = f(1:(index-1));
            rest = f(index:end);
            if str2double(hash) == hash_src
                new_file = [hash_target rest];
                system(sprintf('mv "%s" "%s"', fullfile(root,files{i}), fullfile(root,new_file)));
            end
        end
    end
    pg.close();
end

