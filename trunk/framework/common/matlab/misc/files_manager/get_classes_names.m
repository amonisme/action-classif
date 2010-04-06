function classes = get_classes_names(directory)
    files = dir(directory);
    classes = {files([files(:).isdir] & not(strcmp({files(:).name},'.') | strcmp({files(:).name},'..'))).name}';
    
    i=1;
    while(i<=length(classes))
        name = classes{i};
        if name(1) == '.'
            classes = classes([1:(i-1) (i+1):end]);
        else
            i = i+1;
        end
    end
end

