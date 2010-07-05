function V = collect_basis_feat_vector(bounding_boxes, feat, ids, assign, i, j)
    n_img = length(feat);
    
    if i>j
        t = i;
        i = j;
        j = t;
    end
    
    n = 0;
    for k=1:n_img
        n_i = length(find(assign{k} == i));
        n_j = length(find(assign{k} == j));
        n = n + n_i * n_j;
    end
    
    V = cell(n_img,1);
    n = 1;
    for k=1:n_img
        I = find(assign{k} == i);
        J = find(assign{k} == j);
        width = bounding_boxes(k,3) - bounding_boxes(k,1) + 1;
        height = bounding_boxes(k,4) - bounding_boxes(k,2) + 1;
        scale = max(width, height);
        
        if ~isempty(I) && ~isempty(J)
            featI = repmat(reshape(feat{k}(I,1:2),length(I),1,2), 1, length(J));
            featJ = repmat(reshape(feat{k}(J,1:2),1,length(J),2), length(I), 1);
            V{k} = cat(3, (featJ - featI) / scale, ...
                       repmat(ids(k), length(I), length(J)), ...
                       repmat(k, length(I), length(J)), ...
                       repmat(I, 1, length(J)), ... 
                       repmat(J', length(I), 1));
            V{k} = reshape(V{k}, length(I)*length(J), 6);
        end        
    end
    V = cat(1,V{:});
end