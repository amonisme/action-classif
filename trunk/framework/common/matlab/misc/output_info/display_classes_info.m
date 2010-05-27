function display_classes_info(classes)
    n_classes = length(classes);
    write_log(sprintf('Found %d classes:\n',n_classes));
    for i=1:n_classes
        if length(classes(i).subclasses) == 1
            write_log(sprintf('- %s: %d files.\n',classes(i).name, size(classes(i).subclasses.files,1))); 
        else
            write_log(sprintf('- %s:\n', classes(i).name));
            for j=1:length(classes(i).subclasses)
                write_log(sprintf('   %s: %d files.\n',classes(i).subclasses(j).name, size(classes(i).subclasses(j).files,1))); 
            end
        end
    end
    global HASH_PATH;
    write_log(sprintf('----\nHash code is: %s\n\n', HASH_PATH));
end

