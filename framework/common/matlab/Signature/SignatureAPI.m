classdef SignatureAPI < handle
    % Signature Interface 
    properties
        channels            % input channels
        channel_sig_size    % Dimensionnality of the signature for one channel
        total_sig_size      % Dimensionnality of the total signature
        train_sigs          % Training signatures
        norm                % Norm used to normalize signatures
    end
    
    methods (Abstract)
        % Learn the training set signatures
        learn(obj, Ipaths)
        
        % Return the signature of the Images
        sigs = get_signatures(obj, Ipaths)        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
end

