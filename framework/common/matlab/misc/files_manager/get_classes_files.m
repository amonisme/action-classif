function classes = get_classes_files(DB)
    load(DB, 'classes'); % loads array of struct(name : string, subclasses : struct(name, path))
    root = fileparts(DB);
  
    for i=1:length(classes)
        for j=1:length(classes(i).subclasses)
            jpg_files = get_files(fullfile(root,classes(i).subclasses(j).path), 'jpg');
            png_files = get_files(fullfile(root,classes(i).subclasses(j).path), 'png');            
            classes(i).subclasses(j).files = cat(1,jpg_files, png_files);
        end
    end
end

function files = get_files(root, ext)
    if nargin < 2
        ext = '*';
    end
    files = dir(fullfile(root,sprintf('*.%s',ext)));
    files = files(~[files(:).isdir]);
    files = {files(:).name}';
end