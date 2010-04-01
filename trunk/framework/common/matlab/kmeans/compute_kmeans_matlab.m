function centers = compute_kmeans_matlab(descr, K, maxiter)
    [id centers] = kmeans(descr, K, 'emptyaction', 'singleton','onlinephase','off');
end

