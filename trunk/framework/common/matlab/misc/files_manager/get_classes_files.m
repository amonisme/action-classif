function files = get_classes_files(root)
    classe = get_classes_names(root);
    files = [];
    for i=1:size(classe,1)
        path = fullfile(root,classe{i},'*.jpg');
        f_jpg = dir(path);
        f_jpg = f_jpg(~[f_jpg(:).isdir]);
        
        path = fullfile(root,classe{i},'*.png');
        f_png = dir(path);
        f_png = f_png(~[f_png(:).isdir]);        
        
        names = struct('name',{f_jpg(:).name f_png(:).name}');
        files = cat(1,files,struct('name', classe{i}, 'path', path, 'files', names));
    end
end

