function makeTrainNTest(root_src, root_dest, n_train)
    classes = get_classes_files(root_src);
    n_classes = size(classes, 1);
    
    train_root = fullfile(root_dest, 'train');
    test_root = fullfile(root_dest, 'test');
    
    if not(isdir(train_root))
        mkdir(train_root);
    end
    if not(isdir(test_root))
        mkdir(test_root);
    end
    
    for i=1:n_classes
        fprintf('Processing class %s...\n', classes(i).name);
        
        n_files = size(classes(i).files,1);
        if(n_files <= n_train)
            throw(MException('', sprintf('Only %d files for class "%s". Cannot generate %d test files.\n',n_files, classes(i).name, n_train)));
        end
        
        index = randperm(n_files);
        
        copy_files(root_src, train_root, classes(i), index(1:n_train));
        copy_files(root_src, test_root, classes(i), index((n_train+1):end));        
    end
end

function copy_files(root_src, root_dest, classe, index)
    path_src = fullfile(root_src, classe.name);
    path = fullfile(root_dest, classe.name);
    
    if not(isdir(path))
        mkdir(path);
    end
    
    f = dir(path);
    f = f(not([f(:).isdir]));
    
    for i=1:size(f, 1)
        delete(fullfile(path, f(i).name));
    end
    
    f = classe.files(index);
    for i=1:size(f, 1)
        copyfile(fullfile(path_src, f(i).name), fullfile(path, f(i).name));
    end
end
    

