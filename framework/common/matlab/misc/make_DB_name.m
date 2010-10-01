function DB = make_DB_name(db, type)
    if isdir(db)
        DB = fullfile(db, 'ImageSets', 'Action', sprintf('*_%s.txt', type));
    else
        [db_root db_name] = fileparts(db);
        DB = fullfile(db_root, sprintf('%s.%s.mat', db_name, type));
    end
end