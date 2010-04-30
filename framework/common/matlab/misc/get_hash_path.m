function hash = get_hash_path(Ipaths, count_dir)
    if nargin < 2
        count_dir = 1;
    end
    
    i1 = Ipaths{1};
    
    for i = 1:length(Ipaths)
        [dir file] = fileparts(Ipaths{i});
        Ipaths{i} = file;
    end
    
    p = uint32(cat(2, Ipaths{:}));
    hash = uint32(1);
    prime = uint32(1967309);
    
    for i=1:length(p)
        hash = mod(hash*uint32(p(i)),prime);
    end
    
    if count_dir
        [d db] = fileparts(fileparts(fileparts(fileparts(i1))));
        db = uint32(db);
        for i=1:length(db)
            hash = mod(hash*db(i),prime); 
        end
    end
end

