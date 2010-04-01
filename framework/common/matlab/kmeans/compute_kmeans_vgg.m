function centers = compute_kmeans_vgg(descr, K, maxiter)
    centers = vgg_kmeans(descr', K, maxiter)';
end

