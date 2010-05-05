function init_matlab(fbp,tid,iid,hash,temp_dir,lib_dir)
    setup_path();
    init_global();
        
    global TID IID FILE_BUFFER_PATH HASH_PATH TEMP_DIR LIB_DIR;    
    
    if nargin == 0
        FILE_BUFFER_PATH = './';
    else
        FILE_BUFFER_PATH = fbp;
    end
    if ~isdir(FILE_BUFFER_PATH)
        mkdir(FILE_BUFFER_PATH);
    end

    if nargin >= 3
        TID = tid;
        IID = iid;        
    end
    if nargin >= 4
        HASH_PATH = hash;
    end
    if nargin >= 5
        TEMP_DIR = temp_dir;
    end
    if nargin >= 6
        LIB_DIR = lib_dir;
    end
    
    
    % For some reasons, if MATLAB never saw a class it may have trouble to
    % load a structure with a field pointing to this class althought it is
    % in the path.
    kernel_init = Linear();
    kernel_init = Polynomial();    
    kernel_init = Sigmoid();
    kernel_init = RBF();
    kernel_init = Chi2();
    kernel_init = Intersection();
end
