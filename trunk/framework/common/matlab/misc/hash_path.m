function hash = hash_path(Ipaths)
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
end

