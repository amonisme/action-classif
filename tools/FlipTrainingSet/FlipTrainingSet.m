function FlipTrainingSet(root_src, root_dest)
    classes = get_classes_files(fullfile(root_src, 'train'));
    n_classes = size(classes, 1);
    
    if not(isdir(root_dest))
        mkdir(root_dest);
    end
    if not(isdir(fullfile(root_dest, 'test')))
        mkdir(fullfile(root_dest, 'test'));
    end    
   
    for i=1:n_classes
        fprintf('Processing class %s...\n', classes(i).name);

        if not(isdir(fullfile(root_dest, 'train', classes(i).name)))
            mkdir(fullfile(root_dest, 'train', classes(i).name));
        end  
        if not(isdir(fullfile(root_dest, 'test', classes(i).name)))
            mkdir(fullfile(root_dest, 'test', classes(i).name));
        end    
                
        copyfile(fullfile(root_src, 'train', classes(i).name), fullfile(root_dest, 'train', classes(i).name));
        copyfile(fullfile(root_src, 'test', classes(i).name), fullfile(root_dest, 'test', classes(i).name));        
        
        n_files = size(classes(i).files,1);
        
        for j=1:n_files          
           fprintf('Processing file %d/%d...\n', j, n_files);
 
           file = classes(i).files(j).name;
           I = imread(fullfile(fullfile(root_src, 'train', classes(i).name), file));
           I = I(:,size(I,2):-1:1,:);

           [d file] = fileparts(file);
           file = fullfile(fullfile(root_dest, 'train', classes(i).name),[file '_flipped' '.jpg']);
           
           imwrite(I, file, 'jpg');
        end        
    end
end