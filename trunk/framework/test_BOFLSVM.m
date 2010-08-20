cd('/data/vdelaitr/src/framework');

set_cluster_config;
global USE_PARALLEL USE_CLUSTER;

USE_PARALLEL = 1;
USE_CLUSTER = 0;

evaluate(BOFLSVM(1024,1,9,'B'), '/data/vdelaitr/DB_FeiFei/DB', 'feifei_saxophone', '../../FEIFEI_saxophone');