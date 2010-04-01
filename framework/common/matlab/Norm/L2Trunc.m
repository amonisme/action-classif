classdef L2Trunc < L2
    % Norm L2 with threshold truncation
    
    properties
        threshold
    end
        
    methods 
        %------------------------------------------------------------------
        % Norm L2
        function A = normalize(obj, A)
            A = normalize@L2(obj, A);
            max = obj.norm*obj.threshold;
            A(A>max) = max;
            A = normalize@L2(obj, A);
        end

        %------------------------------------------------------------------
        % Construtor
        function obj = L2Trunc(threshold, norm)
            if nargin<1
                threshold = 0.2;
            end
            if nargin<2
                norm = 1;
            end
            obj = obj@L2(norm);
            obj.threshold = threshold;
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('L2 (norm = %s, truncation over %s)', num2str(obj.norm), num2str(obj.norm*obj.threshold));
        end
        function str = toFileName(obj)
            str = sprintf('L2[N(%s)-T(%s)]', num2str(obj.norm), num2str(100*obj.threshold));
        end
        function str = toName(obj)
            str = 'L2T';
        end   
    end
end
