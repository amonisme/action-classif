function double2single(file)
    system(sprintf('cp %s %s2', file, file));
    
    load(file);
    n = size(descr, 1);
    for i=1:n
        descr{i} = single(descr{i}); 
    end
    
    save(file, 'descr');
end

