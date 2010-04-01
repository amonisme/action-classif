function init_matlab(fbp,tid,iid)
    setup_path();
    init_global();
        
    global TID IID;    
    global FILE_BUFFER_PATH;
    
    if nargin == 0
        FILE_BUFFER_PATH = './';
    else
        FILE_BUFFER_PATH = fbp;
    end
    if ~isdir(FILE_BUFFER_PATH)
        mkdir(FILE_BUFFER_PATH);
    end

    if nargin == 3
        TID = tid;
        IID = iid;        
    end
end
