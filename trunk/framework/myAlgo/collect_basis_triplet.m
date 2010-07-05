function V = collect_basis_triplet(feat, ids, assign, i, j, k)
    n_img = length(feat);
    
    if i>j
        t = i;
        i = j;
        j = t;
    end
    
    n = 0;
    for a=1:n_img
        n_i = length(find(assign{a} == i));
        n_j = length(find(assign{a} == j));
        n = n + n_i * n_j;
    end
    
    V = zeros(n, 3);
    n = 1;
    for a=1:n_img
        I = find(assign{a} == i);
        J = find(assign{a} == j);
        K = find(assign{a} == k);
        n0 = n;
        for u=1:length(I)   
            for v=1:length(J)
                if J(v) == I(u)
                    continue;
                end
                for w=1:length(K)
                    if K(w) == I(u) || K(w) == J(v)
                        continue;
                    end
                    p = feat{a}(I(u),1) + 1i * feat{a}(I(u),2);
                    q = feat{a}(J(v),1) + 1i * feat{a}(J(v),2);
                    r = feat{a}(K(w),1) + 1i * feat{a}(K(w),2);
                    
                    pq = q - p;
                    pr = r - p;
                    
                    f = pr / pq;
                                                       
                    angle_feat = angle(f);
                    norm_feat = norm(f);
                    
                    V(n,1:2) = [norm_feat angle_feat];
                    n = n + 1; 
                end
            end
        end
        n1 = n-1;
        V(n0:n1, 3) = ids(a);
    end
end