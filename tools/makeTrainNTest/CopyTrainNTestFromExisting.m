function CopyTrainNTestFromExisting(dataset_src, database_src, database_dest)
    classes = get_classes_files(dataset_src);
    n_classes = size(classes, 1);
    
    train_root = fullfile(database_dest, 'train');
    test_root = fullfile(database_dest, 'test');

    if not(isdir(database_dest))
        mkdir(database_dest);
    end
    if not(isdir(train_root))
        mkdir(train_root);
    end
    if not(isdir(test_root))
        mkdir(test_root);
    end
    
    for i=1:n_classes
        fprintf('Processing class %s...\n', classes(i).name);
        
        dest_dir = fullfile(train_root, classes(i).name);
        if ~isdir(dest_dir)
            mkdir(dest_dir);
        end                
        d =    dir(fullfile(database_src, 'train', classes(i).name));
        copy_files(fullfile(dataset_src , classes(i).name), fullfile(train_root, classes(i).name), {d(:).name});
        
        dest_dir = fullfile(test_root, classes(i).name);
        if ~isdir(dest_dir)
            mkdir(dest_dir);
        end          
        d =    dir(fullfile(database_src, 'test', classes(i).name));        
        copy_files(fullfile(dataset_src , classes(i).name), fullfile(test_root, classes(i).name), {d(:).name});    
    end
end

function copy_files(root_src, root_dest, files)
    for i=1:size(files, 2)
        file = fullfile(root_src, files{i});
        if exist(file, 'file') == 2          
            if ~isdir(file)
                copyfile(file, fullfile(root_dest, files{i}));
            end
        else
            fprintf('Unknown file %s\n', file);
        end
    end
end
    

