function init_global()
    global USE_PARALLEL USE_CLUSTER SHOW_BAR EXPERIMENT_DIR TEMP_DIR LIB_DIR CLUSTER_WORKING_DIR CLUSTER_USER;
    USE_PARALLEL = 1;
    USE_CLUSTER = 0;
    SHOW_BAR = 0;    
    EXPERIMENT_DIR = 'experiments';    
    TEMP_DIR = 'temp';
    LIB_DIR = 'common/libs';
    CLUSTER_WORKING_DIR = '/data/vdelaitr/src/framework';
    CLUSTER_USER = 'vdelaitr';
end
