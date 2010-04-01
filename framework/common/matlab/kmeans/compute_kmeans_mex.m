function centers = compute_kmeans_mex(descr, K, maxiter)
    [centers assign niter] = kmeans_mex(descr', K, maxiter);
    centers = centers';
end

