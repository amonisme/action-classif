function compile_for_cluster(copy_libs)
    global CLUSTER_WORKING_DIR CLUSTER_USER;
    
    if nargin < 1
        copy_libs = 0;
    end
    
    current_dir = cd;
    
    copy_src_to_cluster(copy_libs);
    
    main_file = 'run_instance_on_cluster.m'; 
    target_exec = fullfile(CLUSTER_WORKING_DIR,['exec' main_file(1:end-2)], main_file(1:end-2));
    system(sprintf('rm -f %s', target_exec));
    
    compileAndRunForCluster(main_file,CLUSTER_USER,CLUSTER_WORKING_DIR,{},'2048mb')
    
    cd(current_dir);
end

