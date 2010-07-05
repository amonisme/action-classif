function showimg_unit_feat(Ipath, feat, i, j)
    bb = get_bb_info(Ipath);
    w = bb(4) - bb(2);
    h = bb(5) - bb(3);
    scale = max(w,h);
    imshow(Ipath);
    hold on;
        
    x = feat(i, 1);
    y = feat(i, 2);      
    if x<1 || y<1
        s = scale;
    else
        s = 1;
    end
    fnplt(rsmak('circle',5,[x y]*s),3,'y');
    
    x = feat(j, 1);
    y = feat(j, 2);  
    if x<1 || y<1
        s = scale;
    else
        s = 1;
    end    
    fnplt(rsmak('circle',5,[x y]*s),3,'y');    
    hold off;
end
