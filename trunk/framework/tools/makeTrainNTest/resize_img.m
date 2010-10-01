function resize_img(root, max_size)
    fprintf('Entering %s\n', root);
    d = dir(root);
    
    for i=1:length(d)
        file = fullfile(root, d(i).name);
        if isdir(file) && d(i).name(1) ~= '.'
            resize_img(file, max_size);
        else
            [a b c] = fileparts(file);
            if strcmp(c, '.jpg') || strcmp(c, '.png')
                resize_img_from_file(file, max_size, c(2:end));
            end
        end            
    end
end

function resize_img_from_file(file, max_size, ext)
    I = imread(file);
    s = max(size(I));
    I = imresize(I, max_size/s);
    imwrite(I, file, ext);
end
