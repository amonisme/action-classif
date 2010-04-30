classdef Dense < DetectorAPI
    % Dense features detector
    properties (SetAccess = protected, GetAccess = protected)
        spacing
        lib
        lib_name
    end
    
%     methods (Static = true)
%         %------------------------------------------------------------------
%         function obj = loadobj(a)
%             obj = a;
%             if obj.lib == 0
%                 obj.lib_name = 'mylib';
%             elseif obj.lib == 1
%                 obj.lib_name = 'cd';                   
%             end
%         end    
%     end    
    methods (Access = protected)
        %------------------------------------------------------------------
        function feat = impl_mylib(obj, Ipath)
            n_scales = size(obj.spacing,1);
            feat = cell(n_scales,1);
            
            info = imfinfo(Ipath);
            w = info.Width;
            h = info.Height;
            
            for i=1:n_scales

                space = obj.spacing(i);
                coordy = ((1+space):space:(h-space))';
                coordx0 = (floor(1+space):space:(w-space))';
                coordx1 = (floor(1+3*space/2):space:(w-space))';

                n_row = size(coordy, 1);
                n_col0 = size(coordx0, 1);
                n_col1 = size(coordx1, 1);
                n = floor(n_row/2)*(n_col0+n_col1) + mod(n_row,2)*n_col1;
                feat{i} = zeros(n, 5);
                
                if size(feat{i},1) == 0
                    feat = {feat{1:i}};
                    break;
                end

                curr = 1;
                for j=1:n_row
                    if mod(j,2)
                        feat{i}(curr:(curr+n_col1-1), 1) = coordx1;
                        feat{i}(curr:(curr+n_col1-1), 2) = coordy(j);
                        curr = curr+n_col1;
                    else
                        feat{i}(curr:(curr+n_col0-1), 1) = coordx0;
                        feat{i}(curr:(curr+n_col0-1), 2) = coordy(j);
                        curr = curr+n_col0;
                    end
                end

                scale = 1.2 * obj.spacing(i) / 6;
                feat{i}(:,3) = scale * ones(n,1);
            end
            feat = cat(1, feat{:});
        end
        
        %------------------------------------------------------------------  
        function feat = impl_colordescriptor(obj, Ipath)
            n_scales = size(obj.spacing,1);
            feat = cell(n_scales,1);
            for i=1:n_scales
                args = sprintf('--detector densesampling --ds_spacing %d', obj.spacing(i));
                feat{i} = run_colorDescriptor(Ipath, args);
                if size(feat{i},1) == 0
                    feat = feat{1:i};
                    break;
                end
            end
            feat = cat(1, feat{:});
        end
    end
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = Dense(spacing, lib)     
            if(nargin < 1)
                spacing = 12;
            end            
            if(nargin < 2)
                lib = 'mylib';
            end
            
            obj = obj@DetectorAPI('S');
            obj.lib_name = lib;
            obj.spacing = spacing;
            
            if(strcmpi(lib, 'mylib'))
                obj.lib = 0;
            else
                if(strcmpi(lib, 'cd'))
                    obj.lib = 1;
                else
                    throw(MException('',['Unknown library for computing dense features: "' lib '".\nPossible values are: "mylib" (for myLib) and "cd" (for colorDescriptor).\n']));
                end
            end
        end
        
        %------------------------------------------------------------------
        % Returns feature points of the image specified by Ipath 
        function feat = get_features(obj, Ipath)
            if obj.lib == 0
                feat = obj.impl_mylib(Ipath);
            else
                feat = obj.impl_colordescriptor(Ipath);
            end      
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('DENSE[Spacing = %d, Library: %s]', obj.spacing, obj.lib_name);
        end
        function str = toFileName(obj)
            str = sprintf('DENSE[%s-%d]', obj.lib_name, obj.spacing);
        end
        function str = toName(obj)
            str = sprintf('DENSE');
        end        
   end
end
