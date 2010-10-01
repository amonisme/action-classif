function init_global()
    global WORKING_ROOT USE_PARALLEL USE_CLUSTER SHOW_BAR EXPERIMENT_DIR TEMP_DIR LIB_DIR CLUSTER_WORKING_DIR CLUSTER_USER;
    WORKING_ROOT = cd();
    USE_PARALLEL = 1;
    USE_CLUSTER = 0;
    SHOW_BAR = 0;    
    EXPERIMENT_DIR = '/data/vdelaitr/results';    
    TEMP_DIR = '/data/vdelaitr/temp';
    LIB_DIR = 'common/libs';
    CLUSTER_WORKING_DIR = '/data/vdelaitr/bin';
    CLUSTER_USER = 'vdelaitr';
end
