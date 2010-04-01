classdef Harris < DetectorAPI
    % Dense features detector
    properties (SetAccess = protected, GetAccess = protected)
        harrisTh
        harrisK
        laplaceTh
        lib
        lib_name
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------  
        function feat = impl_colorDescriptor(obj, Ipath)
            args = sprintf('--detector harrislaplace --harrisThreshold %s --harrisK %s --laplaceThreshold %s', num2str(obj.harrisTh), num2str(obj.harrisK), num2str(obj.laplaceTh));
            feat = run_colorDescriptor(Ipath, args);
        end
    end
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = Harris(rotInvariant, harrisTh, harrisK, laplaceTh, lib)
            if(nargin < 1)
                rotInvariant = 'S';
            end
            if(nargin < 2)
                harrisTh = 1e-9;
            end
            if(nargin < 3)
                harrisK = 0.06;
            end
            if(nargin < 4)
                laplaceTh = 0.03;
            end    
            if(nargin < 5)
                lib = 'colorDescriptor';
            end
            
            obj = obj@DetectorAPI(rotInvariant); 
            obj.lib_name = lib;
            obj.harrisTh = harrisTh;
            obj.harrisK = harrisK;
            obj.laplaceTh = laplaceTh;
            
            if(strcmpi(lib, 'colorDescriptor'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for computing Harris-Laplace features: "' lib '".\nPossible values are: "colordescr".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Returns feature points of the image specified by Ipath 
        function feat = get_features(obj, Ipath)          
            feat = obj.impl_colorDescriptor(Ipath);
            
            if ~obj.rotInvariant
                feat = obj.scale_only(feat);
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            if obj.rotInvariant
                RI = 'RS';
            else
                RI = 'S';
            end
            str = sprintf('HARRIS[rotation invariant = %s, threshold = %s, K = %s, Laplace threshold = %s, library: %s]', RI, num2str(obj.harrisTh), num2str(obj.harrisK), num2str(obj.laplaceTh), obj.lib_name);
        end
        function str = toFileName(obj)
            if obj.rotInvariant
                RI = 'RS';
            else
                RI = 'S';
            end
            str = sprintf('HARRIS[RI(%s)-H(%s)-K(%s)-L(%s)-Lib(%s)]', RI, num2str(obj.harrisTh), num2str(obj.harrisK), num2str(obj.laplaceTh), obj.lib_name);
        end
        function str = toName(obj)
            if obj.rotInvariant
                RI = 'RS';
            else
                RI = 'S';
            end
            str = sprintf('HARRIS(%s)',RI);
        end
    end
end
