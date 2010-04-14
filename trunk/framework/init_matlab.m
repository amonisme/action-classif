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
