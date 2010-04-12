function run_instance_on_cluster(tid, iid, hash, fun)
    maxNumCompThreads(1);

    iid = str2double(iid);
    
    init_global();        
    set_cluster_config();
    
    global TID IID TEMP_DIR FILE_BUFFER_PATH HASH_PATH;  
    TID = tid;
    IID = iid;    
    HASH_PATH = hash;
    FILE_BUFFER_PATH = fullfile(TEMP_DIR, TID, num2str(IID));
    if ~isdir(FILE_BUFFER_PATH)
        mkdir(FILE_BUFFER_PATH);
    end    

    eval(sprintf('init_script(@%s)', fun));
end

