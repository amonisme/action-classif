function display_classes_info(classes)
    n_classes = size(classes,1);
    write_log(sprintf('Found %d classes:\n',n_classes));
    for i=1:n_classes
        write_log(sprintf('- %s: %d files.\n',classes(i).name, size(classes(i).files,1))); 
    end
    global HASH_PATH;
    write_log(sprintf('----\nHash code is: %s\n\n', HASH_PATH));
end

