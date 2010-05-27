function build_my_DB(root)
    classes_names = get_classes_names(fullfile(root,'train'));
    traintest = {'train' 'test'};
    
    [d db] = fileparts(root);
 
    classes = struct('name', classes_names, 'subclasses', struct('name', '', 'path', []));
    for i = 1:2
        for j=1:length(classes_names)
            classes(j).subclasses.path = fullfile(sprintf('%s/%s', traintest{i}, classes_names{j}));
        end
        file = fullfile(root, sprintf('%s.%s.mat', db, traintest{i}));
        save(file, 'classes');
    end     
end

