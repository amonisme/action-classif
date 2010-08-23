function DB = make_DB_name(root, name, type)
    if isempty(name)
        DB = fullfile(root, 'ImageSets', 'Action', sprintf('*_%s.txt', type));
    else
        DB = fullfile(root, sprintf('%s.%s.mat', name, type));
    end
end