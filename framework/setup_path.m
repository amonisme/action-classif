function setup_path()
    p = paths();
    
    for i = 1:length(p)
        addpath(p{i});
    end
end

