function [best_score i j] = fit_unit_feat(feat, descr, bounding_box, unit_feat, Ipath)   
    width = bounding_box(3) - bounding_box(1) + 1;
    height = bounding_box(4) - bounding_box(2) + 1;
    scale = max(width, height);
    feat = feat / scale;
    
    n_feat = size(feat, 1);
    sc = (descr * unit_feat.c1') * (descr * unit_feat.c2')';                              
    best_score = -Inf;    
    for x=1:n_feat
        if x == 1
            vects = feat(:,1:2) - repmat(feat(x,1:2) + unit_feat.p, n_feat, 1);
            VectsTSigma = vects * unit_feat.invsigma;
            VectsTSigmaVects2 = sum(VectsTSigma .* vects, 2) / 2;
            xTO1 = [0 0];
        else
            xTO1 = feat(1,1:2) - feat(x,1:2);
        end
        d = VectsTSigmaVects2 + VectsTSigma * xTO1' + (xTO1 * unit_feat.invsigma * xTO1') / 2;
        
        J = (d<10);        
        if ~isempty(find(J,1))                
            [smax y] = max(sc(x,J)' .* exp(-d(J)));        
            if best_score < smax
                best_score = smax;
                i = x;
                J = find(J);
                j = J(y); 
            end
        end
    end 
    
    if nargin >= 5
        showimg_unit_feat(Ipath, feat, i, j);
    end
end