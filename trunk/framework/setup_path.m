function setup_path()
    addpath(cd);
    p = paths();
    
    for i = 1:length(p)
        addpath(p{i});
    end
end

