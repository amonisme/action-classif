
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% detection_config: Initializes various constants
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global config;

% Feature parameters (set according to the paper N.Dalal and B.Triggs, "Histograms of Oriented Gradients
% for Human Detection" CVPR 2005)
config.HOG_CELL_DIMS = [16 16 180];
config.NUM_HOG_BINS = [2 2 9];
config.SKIN_CELL_DIMS = [2 2];
config.HOG_WTSCALE = 2;
config.HOG_NORM_EPS = 1;
config.HOG_NORM_EPS2 = 0.01;
config.HOG_NORM_MAXVAL = 0.2;
config.MS_SIGMA = [8 16 log(1.3)];

% Scanning parameters
config.PYRAMID_SCALE_RATIO = 1.1;
config.IMG_MARGIN = [0.1 0.1];
config.DETECTION_IMG_MIN_NUM_PIX = 1000^2;  % if the number of pixels in a detection image is < DETECTION_IMG_SIDE^2, scales up the image to meet that threshold
config.DETECTION_IMG_MAX_NUM_PIX = 1500^2;  
config.PATCH_DIMS = [96 64];
config.DENSE_DETECTION = false;
config.DETECT_SVM_THRESH = 0; % higher = more more precision, less recall
config.DETECTION_ANGLES = 0;%-45:15:45;   % What angles to scan over
config.DO_FLIPPED_HITS = true; % Also searches the left-to-right flipped image 
config.MAX_AGGLOMERATIVE_CLUSTER_ELEMS = 500;

config.TORSO_ASPECT_RATIO = 1.5;    % height/width of torsos
config.CLUSTER_HITS_CUTOFF=0.6; % clustering threshold for bounds hypotheses

config.NUM_POSELETS = 1178;
