classdef C_SIFT < DescriptorAPI
	% Sift detector
    properties (SetAccess = protected, GetAccess = protected)
        lib
        lib_name
    end
  
    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if obj.lib == 0
                obj.lib_name = 'cd';                   
            end
        end             
        %------------------------------------------------------------------
        function descr = impl_colorDescriptor(Ipath, feat, scale)
            [f descr] = run_colorDescriptor(Ipath, scale, '--descriptor csift', feat);
        end
    end

    methods (Access = protected)
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function descr = compute_descriptors(obj, Ipath, feat, scale)
            descr = obj.impl_colorDescriptor(Ipath, feat, scale);
        end    
    end    
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = C_SIFT(norm, lib)
            if(nargin < 1)
                norm = norm.L2Trunc();
            end
            if(nargin < 2)
                lib = 'cd';
            end

            obj = obj@DescriptorAPI(norm); 
            obj.lib_name = lib;
                        
            if strcmpi(lib, 'cd')
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for computing C-SIFT descriptors: "' lib '".\nPossible value is: "cd" (for colorDescriptor).\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('C-SIFT[normalization: %s, library: %s]', obj.norm.toString(), obj.lib_name);
        end
        function str = toFileName(obj)
            str = sprintf('C-SIFT[%s-%s]', obj.lib_name, obj.norm.toFileName());
        end
        function str = toName(obj)
            str = sprintf('C-SIFT(%s)', obj.norm.toName());
        end
    end
end
