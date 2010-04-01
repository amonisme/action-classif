classdef SIFT < DescriptorAPI
	% Sift detector
    properties (SetAccess = protected, GetAccess = protected)
        lib
        lib_name
    end
  
    methods (Static)
        %------------------------------------------------------------------
        function descr = impl_colorDescriptor(Ipath, feat)
            [f descr] = run_colorDescriptor(Ipath, '--descriptor sift', feat);
        end
        
        %------------------------------------------------------------------
        function descr = impl_vlfeat(Ipath, feat)
            I = single(rgb2gray(imread(Ipath)));  
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
                lib = 'colorDescriptor';
            end

            obj = obj@DescriptorAPI(norm); 
            obj.lib_name = lib;
                        
            if strcmpi(lib, 'colorDescriptor')
                obj.lib = 0;
            else
                if strcmpi(lib, 'vlfeat')
                    obj.lib = 1;
                else
                    throw(MException('',['Unknown library for computing SIFT descriptors: "' lib '".\nPossible values are: "colordescr" and "vlfeat".\n']));
                end
            end
        end
        
        %------------------------------------------------------------------
        % Returns descriptors of the image specified by Ipath given its
        % feature points 'feat' (one per line)
        function descr = compute_descriptors(obj, Ipath, feat)
            if(obj.lib == 0)
                descr = obj.impl_colorDescriptor(Ipath, feat);
            else
                descr = obj.impl_vlfeat(Ipath, feat);
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('SIFT[normalization: %s, library: %s]', obj.norm.toString(), obj.lib_name);
        end
        function str = toFileName(obj)
            str = sprintf('SIFT[Norm(%s)-Lib(%s)]', obj.norm.toFileName(), obj.lib_name);
        end
        function str = toName(obj)
            str = sprintf('SIFT(%s)', obj.norm.toName());
        end
    end
end
