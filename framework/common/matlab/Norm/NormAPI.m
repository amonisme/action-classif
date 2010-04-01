classdef NormAPI
    % Abstract class for norms    
    methods (Abstract)
        %------------------------------------------------------------------
        % Normalize each line of A
        B = normalize(obj, A)
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj);
    end
end
