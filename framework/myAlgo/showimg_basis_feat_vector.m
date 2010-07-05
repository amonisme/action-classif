function showimg_basis_feat_vector(src,evnt)
    global CLICK_STRUCT FEAT_CELL;

    point = get(get(src,'Parent'), 'CurrentPoint');
    mouse_x = point(1,1);
    mouse_y = point(1,2);
    
    V = CLICK_STRUCT.V;
    feat = CLICK_STRUCT.feat;    
    
    D = V(:,1:2) - repmat([mouse_x mouse_y], size(V,1), 1);
    D = sum(D .* D, 2);
    [m i] = min(D);
    
    img = V(i,4);
    f1 = feat{img}(V(i,5),1:2);
    f2 = feat{img}(V(i,6),1:2);
    
    fprintf('Opening...\n');
    fprintf('Vector: (%d,%d) -> (%d, %d) = (%f, %f)\n', f1(1), f1(2), f2(1), f2(2), V(i,1), V(i,2));
    
    h = figure;
    FEAT_CELL{h} = [feat{img}(:,1:2) CLICK_STRUCT.assign{img}];
    imshow(CLICK_STRUCT.Ipaths{img});
    hold on;
    
    for k = 1:length(feat{img})
        if k == V(i,5)
            fnplt(rsmak('circle',5,f1),3,'y');
        elseif k == V(i,6)
            fnplt(rsmak('circle',5,f2),3,'y');
        else
            fnplt(rsmak('circle',1,feat{img}(k,1:2)),2,'b');
        end
    end
    
    set(get(get(h, 'Children'), 'Children'),'ButtonDownFcn',@showimg_descr_id);
end