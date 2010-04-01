function classes = get_classes_names(directory)
    files = dir(directory);
    classes = {files([files(:).isdir] & not(strcmp({files(:).name},'.') | strcmp({files(:).name},'..'))).name}';
end

