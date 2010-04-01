function centers = compute_kmeans_vlfeat(descr, K, maxiter)
    m = max(max(descr));
    descr = uint8(255/m*descr);
    centers = vl_ikmeans(descr', K, 'MaxIters', maxiter);
    centers = m/255*double(centers');
end

