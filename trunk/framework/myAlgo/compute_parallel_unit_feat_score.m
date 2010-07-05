function scores = compute_parallel_unit_feat_score(common, I)
    tid = task_open();

    n_img = length(I);
    scores = zeros(n_img, common.n_unit_features_sample);
    
    for j = 1:n_img
        width = common.bounding_boxes(j,3) - common.bounding_boxes(j,1) + 1;
        height = common.bounding_boxes(j,4) - common.bounding_boxes(j,2) + 1;
        scale = max(width, height);
        sfeat = common.feat{I(j)}(:,1:2) / scale;
        sdescr = common.descr{I(j)} * common.basis';
                            
        n_feat = size(sfeat,1);
        k = 1;
        for u = 1:common.n_basis_selected
            sc1 = sdescr(:,common.model(u).c1);
            for v = u:common.n_basis_selected  
                n_descr = length(common.descr{I(j)});
                sc2 = sdescr(:,common.model(u).c2_p(v-u+1).c2);                
                %sc = sc1 * sc2';                
                sc = repmat(sc1, 1, n_descr) + repmat(sc2', n_descr, 1);                
                n_centers = size(common.model(u).c2_p(v-u+1).p, 1);
                for w = 1:n_centers
                    p = common.model(u).c2_p(v-u+1).p(w,:);
                    invsigma = common.model(u).c2_p(v-u+1).invsigma{w};
                    %const_gauss = sqrt(det(invsigma))/(2*pi);
                    best_score = 0;
                    for x=1:n_feat
                        if x == 1
                            vects = sfeat - repmat(sfeat(x,:) + p, n_feat, 1);
                            VectsTSigma = vects * invsigma;
                            VectsTSigmaVects2 = sum(VectsTSigma .* vects, 2) / 2;
                            xTO1 = [0 0];
                        else
                            xTO1 = sfeat(1,:) - sfeat(x,:);
                        end
                        d = VectsTSigmaVects2 + VectsTSigma * xTO1' + (xTO1 * invsigma * xTO1') / 2;
                        J = (d<10);
                        if ~isempty(find(J,1))
                            smax = max(sc(x,J)' .* exp(-d(J)));
                            %best_score = max(best_score, const_gauss * smax); 
                            best_score = max(best_score, smax); 
                        end
                    end
                    scores(j,k) = best_score;
                    k = k + 1;
                end
            end
        end                    
    end    
    
    task_close(tid);
end

