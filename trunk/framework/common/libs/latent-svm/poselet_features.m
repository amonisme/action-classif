function feat = poselet_features(model, img, sbin)
    global config;
    
    config.HOG_CELL_DIMS = config.NUM_HOG_BINS .* [sbin sbin 20];
    config.PATCH_DIMS = [12 8] * sbin;
    
    margin = floor((config.PATCH_DIMS - sbin) / 2);
    img = padarray(img, margin);
    
    [hog h w] = poselet_image2features(img);
    feat = reshape(...
                hog*model.svms(1:end-1,:)+repmat(model.svms(end,:),size(hog,1),1), ...
                h, w, size(model.svms,2));    
end
