function apply_offset(root, minI, offset)    
    d = dir(root);

    mkdir(fullfile(root, 'tmp'));
    
    for i = 1:length(d)
        if length(d(i).name) > 3
            pref = d(i).name(1:3);
            if strcmp(pref,'img')
                num = str2num(d(i).name(4:7));
                if num >= minI
                    new_name = sprintf('img%04d.jpg', num+offset);
                    system(sprintf('cp %s %s', fullfile(root,d(i).name), fullfile(root,'tmp',new_name)));
                end
            end
        end
    end
end

