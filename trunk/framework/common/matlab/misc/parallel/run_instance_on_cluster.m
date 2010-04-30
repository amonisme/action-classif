function run_instance_on_cluster(tid, iid, hash, fun)
    maxNumCompThreads(1);

    iid = str2double(iid);
    
    init_global();        
    set_cluster_config();
    
    global TID IID FILE_BUFFER_PATH HASH_PATH CLUSTER_USER;  
    TID = tid;
    IID = iid;    
    HASH_PATH = hash;
    
    if ~isdir(fullfile('/local', CLUSTER_USER))
        mkdir(fullfile('/local', CLUSTER_USER));
    end
    if ~isdir(fullfile('/local', CLUSTER_USER, TID))
        mkdir(fullfile('/local', CLUSTER_USER, TID));
    end    
    if ~isdir(fullfile('/local', CLUSTER_USER, TID, num2str(IID)))
        mkdir(fullfile('/local', CLUSTER_USER, TID, num2str(IID)));
    end        
    FILE_BUFFER_PATH = fullfile('/local', CLUSTER_USER, TID, num2str(IID));

    eval(sprintf('init_script(@%s)', fun));
    
    rmdir(fullfile('/local', CLUSTER_USER, TID, num2str(IID)), 's');
    rmdir(fullfile('/local', CLUSTER_USER, TID));
end

