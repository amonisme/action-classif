function descr = Descriptor_run_parallel(descriptor, Ipath_feat)
    tid = task_open();
    
    n_img = size(Ipath_feat, 1);
    descr = cell(n_img, 1);
    for i=1:n_img
        task_progress(tid, i/n_img);
        descr{i} = descriptor.compute_descriptors(Ipath_feat{i,1}, Ipath_feat{i,2});
    end
    
    task_close(tid);
end

