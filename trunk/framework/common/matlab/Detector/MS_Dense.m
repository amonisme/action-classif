classdef MS_Dense < Dense
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = MS_Dense(spacing, scale, num_scale, lib)
            if(nargin < 1)
                spacing = 12;
            end
            if(nargin < 2)
                scale = 1.2;
            end
            if(nargin < 3)
                num_scale = 10;
            end
            if(nargin < 4)
                lib = 'mylib';
            end
            
            obj = obj@Dense(floor(spacing*(scale).^(0:(num_scale-1)))',lib);
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('DENSE[spacing = %s%d, library: %s]', sprintf('%d-',obj.spacing(1:(end-1))), obj.spacing(end), obj.lib_name);
        end
        function str = toFileName(obj)
            str = sprintf('DENSE[S(%d%s)-Lib(%s)]', obj.spacing(1), sprintf('-%d', obj.spacing(2:end)), obj.lib_name);
        end
        function str = toName(obj)
            str = sprintf('MSDENSE');
        end
    end
end
