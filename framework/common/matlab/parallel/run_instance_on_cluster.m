function run_instance_on_cluster(tid, iid, fun)
    maxNumCompThreads(1);

    iid = str2double(iid);
    
    init_global();
        
    global TID IID TEMP_DIR FILE_BUFFER_PATH LIB_DIR USE_PARALLEL USE_CLUSTER SHOW_BAR;
    LIB_DIR = '../libs';
    TEMP_DIR = '../../temp';
    USE_PARALLEL = 0;    
    USE_CLUSTER = 0;
    SHOW_BAR = 0;
      
    FILE_BUFFER_PATH = fullfile(TEMP_DIR, tid, num2str(iid));
    if ~isdir(FILE_BUFFER_PATH)
        mkdir(FILE_BUFFER_PATH);
    end

    TID = tid;
    IID = iid;        

    eval(sprintf('init_script(@%s)', fun));
end

