function dim = gather_dim(root)
    classes = get_classes_files(root);
    nclasses = size(classes,1);
    
    dim = [];
   
    for i=1:nclasses
        nfiles = size(classes(i).files,1);
        for j=1:nfiles
            show_progress(1,1,i,nclasses,j,nfiles);
            path = fullfile(classes(i).path, classes(i).files(j).name);
            [h w d] = size(imread(path));
            dim = [dim; h w];
        end
    end
end

