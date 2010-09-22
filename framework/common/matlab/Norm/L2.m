classdef L2 < NormAPI
    % Norm L2
    
    properties
        norm
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm L2
        function A = normalize(obj, A)
            n = sqrt(sum(A.*A, 1));
            n(n == 0) = 1;
            A = (A * obj.norm) ./ repmat(n,size(A,1),1);            
        end

        %------------------------------------------------------------------
        % Construtor
        function obj = L2(norm)
            if nargin == 0
                norm = 1;
            end
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('L2 (norm = %s)', num2str(obj.norm));
        end
        function str = toFileName(obj)
            str = sprintf('L2[%s]', num2str(obj.norm));
        end
        function str = toName(obj)
            str = 'L2';
        end           
    end
end
