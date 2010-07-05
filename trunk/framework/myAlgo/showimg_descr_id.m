function showimg_descr_id(src,evnt)
    global FEAT_CELL;

    point = get(get(src,'Parent'), 'CurrentPoint');
    mouse_x = point(1,1);
    mouse_y = point(1,2);
        
    h = get(get(src,'Parent'), 'Parent');    
    feat = FEAT_CELL{h};
    
    D = feat(:,1:2) - repmat([mouse_x mouse_y], size(feat,1), 1);
    D = sum(D .* D, 2);
    [m i] = min(D);

    fprintf('Descriptor id = %d\n', feat(i,3));
end