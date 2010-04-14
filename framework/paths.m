function p = paths()
    root = cd;
    
    bindir = mexext ;
    if strcmp(bindir, 'dll'), bindir = 'mexw32' ; end
      
    p = {fullfile(root, 'baseline') ...
         fullfile(root, 'common', 'matlab') ... 
         fullfile(root, 'common', 'matlab', 'Classifier') ...  
         fullfile(root, 'common', 'matlab', 'Descriptor') ...  
         fullfile(root, 'common', 'matlab', 'Detector') ...  
         fullfile(root, 'common', 'matlab', 'Kernels') ...                             
         fullfile(root, 'common', 'matlab', 'Norm') ...     
         fullfile(root, 'common', 'matlab', 'Signature') ...                    
         fullfile(root, 'common', 'matlab', 'comparator') ...    
         fullfile(root, 'common', 'matlab', 'parallel') ... 
         fullfile(root, 'common', 'matlab', 'kmeans') ... 
         fullfile(root, 'common', 'matlab', 'misc') ...
         fullfile(root, 'common', 'matlab', 'misc', 'output_info') ...
         fullfile(root, 'common', 'matlab', 'misc', 'output_info', 'progressbar') ...
         fullfile(root, 'common', 'matlab', 'misc', 'files_manager') ...
         fullfile(root, 'common', 'libs', 'colordescriptors') ...
         fullfile(root, 'common', 'libs', 'kmeans') ...          
         fullfile(root, 'common', 'libs', 'svm_mex601', 'bin') ...
         fullfile(root, 'common', 'libs', 'svm_mex601', 'matlab') ...
         fullfile(root, 'common', 'libs', 'vgg') ...
         fullfile(root, 'common', 'libs', 'latent-svm') ...
         fullfile(root, 'common', 'libs', 'clusterMatlabToolbox') ...         
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'aib') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'geometry') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'imop') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'kmeans') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'misc') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'mser') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'plotop') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'quickshift') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'sift') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', 'special') ...
         fullfile(root, 'common', 'libs', 'vlfeat', 'toolbox', bindir)};
end

