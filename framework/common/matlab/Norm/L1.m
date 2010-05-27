classdef L1 < NormAPI
    % Norm L1
    
    properties
        norm
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm L1
        function A = normalize(obj, A)
            for i = 1:size(A,2)
                n = sum(abs(A(:,i)));
                if n ~= 0
                    A(:,i) = obj.norm/n*A(:,i);
                end                
            end
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
            str = sprintf('L1[%s]', num2str(obj.norm));
        end
        function str = toName(obj)
            str = 'L1';
        end    
    end
end
