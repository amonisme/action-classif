function compile_for_cluster(copy_libs)
    global CLUSTER_WORKING_DIR CLUSTER_USER;
    
    if nargin < 1
        copy_libs = 0;
    end
    
    current_dir = cd;
    
    fprintf('Remove old sources...\n');
    system(sprintf('rm -rf %s', CLUSTER_WORKING_DIR));
    system(sprintf('mkdir %s', CLUSTER_WORKING_DIR));    

    fprintf('Copy sources on cluster...\n');
    copy_src_to_cluster(copy_libs);   
    
    fprintf('Compile...\n');
    compileAndRunForCluster('run_instance_on_cluster.m',CLUSTER_USER,CLUSTER_WORKING_DIR,{},'2048mb')
    
    cd(current_dir);
end

