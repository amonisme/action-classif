function plot_basis_feat_vector(V, Ipaths, ids, feat, assign)
    global CLICK_STRUCT;
    
    CLICK_STRUCT = struct('Ipaths', [], 'ids', ids, 'V', V, 'feat', [], 'assign', []);
    CLICK_STRUCT.Ipaths = Ipaths;
    CLICK_STRUCT.feat = feat;
    CLICK_STRUCT.assign = assign;

    colors = [255   0   0; ...
                0 255   0; ...
                0   0 255; ...
              128 128   0; ...
                0 255 255; ...
              255   0 255; ...
                0   0   0];            

    h = figure;
    hold on;
    n_classes = max(V(:,3));
    for i=1:n_classes
        I = V(:,3) == i;
        X = V(I, 1);
        Y = V(I, 2);
        scatter(X,Y); %,30,colors(i,:)/255);        
    end
    hold off;
    
    set(get(get(h, 'Children'), 'Children'),'ButtonDownFcn',@showimg_basis_feat_vector);
end