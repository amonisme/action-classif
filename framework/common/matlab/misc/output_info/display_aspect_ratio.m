function display_aspect_ratio(images)
    n_img = length(images);
    
    im_maxsize = zeros(1, n_img);
    im_aspratio = zeros(1, n_img);
    bndbox_maxsize = zeros(1, n_img);
    bndbox_aspratio = zeros(1, n_img);
    
    for i=1:n_img
        im_maxsize(i) = max(images(i).size);
        im_aspratio(i) = images(i).size(2) / images(i).size(1);
        w = images(i).bndbox(3) - images(i).bndbox(1) + 1;
        h = images(i).bndbox(4) - images(i).bndbox(2) + 1;
        bndbox_maxsize(i) = max(w,h);
        bndbox_aspratio(i) = w / h;
    end
    
    figure    
    bar(sort(im_maxsize));
    grid;
    title('Maximum image size');    

    figure   
    bar(sort(im_aspratio));
    grid;
    title('Image aspect ratio');        
    
    figure   
    bar(sort(bndbox_maxsize));
    grid;
    title('Maximum BB size');
    
    figure     
    bar(sort(bndbox_aspratio));
    grid;
    title('BB aspect ratio');
end
    
