classdef SIFT < DescriptorAPI
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
            elseif obj.lib == 1
                obj.lib_name = 'vlfeat';                   
            end
        end    
        %------------------------------------------------------------------
        function descr = impl_colorDescriptor(Ipath, feat, scale)
            [f descr] = run_colorDescriptor(Ipath, scale, '--descriptor sift', feat);
        end
        
        %------------------------------------------------------------------
        function descr = impl_vlfeat(Ipath, feat, scale)
            if scale ~= 1
                I = single(imresize(rgb2gray(imread(Ipath)),scale)); 
            else
                I = single(rgb2gray(imread(Ipath))); 
            end
            [f descr] = vl_sift(I,'frames',feat);
        end
    end

    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SIFT(norm, lib)
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
                if strcmpi(lib, 'vlfeat')
                    obj.lib = 1;
                else
                    throw(MException('',['Unknown library for computing SIFT descriptors: "' lib '".\nPossible values are: "cd" (for colorDescriptor) and "vlfeat" (for vlfeat).\n']));
                end
            end
        end
        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('SIFT[normalization: %s, library: %s]', obj.norm.toString(), obj.lib_name);
        end
        function str = toFileName(obj)
            str = sprintf('SIFT[%s-%s]', obj.lib_name, obj.norm.toFileName());
        end
        function str = toName(obj)
            str = sprintf('SIFT(%s)', obj.norm.toName());
        end        
    end
    
    methods (Access = protected)  
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function descr = compute_descriptors(obj, Ipath, feat, scale)
            if(obj.lib == 0)
                descr = obj.impl_colorDescriptor(Ipath, feat, scale);
            else
                descr = obj.impl_vlfeat(Ipath, feat, scale);
            end
        end
    end
end
