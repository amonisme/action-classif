classdef DescriptorAPI
    % Abstract class for detectors
    properties (SetAccess = protected, GetAccess = protected)
        norm           % norm used for normalization
    end
  
    methods (Access = protected)
        %------------------------------------------------------------------
        % Constructor
        function obj = DescriptorAPI(norm)
            obj.norm = norm;
        end
    end
    
    methods (Abstract)
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        descr = compute_descriptors(obj, Ipath, feat)
    end
         
    methods             
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function descr = get_descriptors(obj, Ipath, feat)
            descr = obj.compute_descriptors(Ipath, feat);
            descr = obj.norm.normalize(descr);
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end       
end
