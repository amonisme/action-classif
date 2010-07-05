classdef L2 < NormAPI
    % Norm L2
    
    properties
        norm
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm L2
        function A = normalize(obj, A)
            for i = 1:size(A,2)
                n = sqrt(sum(A(:,i).*A(:,i)));
                if n ~= 0
                    A(:,i) = obj.norm/n*A(:,i);
                end                    
            end
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
