classdef L1 < NormAPI
    % Norm L1
    
    properties
        norm
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm L1
        function A = normalize(obj, A)
            m = repmat(max(abs(A), [], 2),1,size(A,2));
            A = obj.norm*A./m;
        end

        %------------------------------------------------------------------
        % Construtor
        function obj = L1(norm)
            if nargin == 0
                norm = 1;
            end
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('L1 (norm = %s)', num2str(obj.norm));
        end
        function str = toFileName(obj)
            str = sprintf('L1[N(%s)]', num2str(obj.norm));
        end
        function str = toName(obj)
            str = 'L1';
        end    
    end
end
