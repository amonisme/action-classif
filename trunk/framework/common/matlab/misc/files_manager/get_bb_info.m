function [bb bb_img_cropped w h] = get_bb_info(img)
    [d f] = fileparts(img);
    bb = load(fullfile(d, sprintf('%s.info', f)), '-ascii');
    
    info = imfinfo(img);
    w = info.Width;
    h = info.Height;
    
    bb_img_cropped(1) = bb(1);
    bb_img_cropped(2) = max(1, bb(2));
    bb_img_cropped(3) = max(1, bb(3));
    bb_img_cropped(4) = min(w, bb(4));
    bb_img_cropped(5) = min(h, bb(5));
end

