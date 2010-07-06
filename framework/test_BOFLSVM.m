cd('/data/vdelaitr/src/framework');

set_cluster_config;
global USE_PARALLEL USE_CLUSTER;

USE_PARALLEL = 1;
USE_CLUSTER = 1;

evaluate(BOFLSVM(1024,1,9), '/data/vdelaitr/DB_FeiFei/DB', 'feifei_bassoon');