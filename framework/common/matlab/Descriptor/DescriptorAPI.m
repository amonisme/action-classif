classdef DescriptorAPI
    % Abstract class for detectors
    properties (SetAccess = protected, GetAccess = protected)
        norm           % norm used for normalization
    end
  
    methods (Access = protected)
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        descr = compute_descriptors(obj, Ipath, feat)
    end
            
    methods        
        %------------------------------------------------------------------
        % Constructor
        function obj = DescriptorAPI(norm)
            obj.norm = norm;
        end
               
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function descr = get_descriptors(obj, Ipath, feat, scale)
            descr = obj.compute_descriptors(Ipath, feat, scale);
            descr = single(descr);
            descr = obj.norm.normalize(descr')';
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
    methods (Static)        
        %------------------------------------------------------------------
        % Run in parallel
        function descr = run_parallel(descriptor, Ipath_feat_scale)
            tid = task_open();

            n_img = size(Ipath_feat, 1);
            descr = cell(n_img, 1);
            for i=1:n_img
                task_progress(tid, i/n_img);
                descr{i} = descriptor.get_descriptors(Ipath_feat_scale{i,1}, Ipath_feat_scale{i,2}, Ipath_feat_scale{i,3});
            end

            task_close(tid);
        end
    end       
end
