function files = get_classes_files(root)
    classe = get_classes_names(root);
    files = [];
    for i=1:size(classe,1)
        path = fullfile(root,classe{i});
        f = dir(path);
        f = f(~[f(:).isdir]);
        names = struct('name',{f(:).name}');
        files = cat(1,files,struct('name', classe{i}, 'path', path, 'files', names));
    end
end

