function feat = Detector_run_parallel(detector, Ipath)
    tid = task_open();
    
    n_img = size(Ipath, 1);
    feat = cell(n_img, 1);
    for i=1:n_img
        task_progress(tid, i/n_img);
        feat{i} = detector.get_features(Ipath{i});
    end
    
    task_close(tid);
end

