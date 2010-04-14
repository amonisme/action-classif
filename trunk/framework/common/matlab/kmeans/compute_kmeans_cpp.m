function centers = compute_kmeans_cpp(descr, K, maxiter)
    global FILE_BUFFER_PATH LIB_DIR;
    
    file_in = fullfile(FILE_BUFFER_PATH,'input.txt');
    file_out = fullfile(FILE_BUFFER_PATH,'output.txt');
    
    save(file_in,'descr','-ascii');
    cmd = fullfile(LIB_DIR, 'kmeans', sprintf('kmeans_cpp %s %d %d %s', file_in, K, maxiter, file_out));
    system(cmd);
    
    centers = load(file_out);
end

