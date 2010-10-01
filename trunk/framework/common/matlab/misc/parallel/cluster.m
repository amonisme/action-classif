function cluster(tid, iid, hash, fun)
    maxNumCompThreads(1);

    iid = str2double(iid);
    
    init_global();        
    set_cluster_config();
    
    global TID IID FILE_BUFFER_PATH HASH_PATH CLUSTER_USER;  
    TID = tid;
    IID = iid;    
    HASH_PATH = hash;
    
    file = fullfile('/local', CLUSTER_USER);
    if ~isdir(file)
        mkdir(file);
    end
    file = fullfile('/local', CLUSTER_USER, TID);
    if ~isdir(file)
        mkdir(file);
    end    
    file = fullfile('/local', CLUSTER_USER, TID, num2str(IID));
    if ~isdir(file)
        mkdir(file);
    end        
    FILE_BUFFER_PATH = file;

    eval(sprintf('init_script(@%s)', fun));
    
    rmdir(file, 's');
    rmdir(fullfile('/local', CLUSTER_USER, TID));
end

