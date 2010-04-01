classdef ClassifierAPI < handle
    % Classifier interface
    
    properties
        signature   % Signature module
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = ClassifierAPI(signature)
            obj.signature = signature;
        end
    end
    
    methods (Abstract)        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        cross_validation = learn(obj, root)
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        [Ipaths classes correct_label assigned_label score] = classify(obj, Ipaths, correct_label)   
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
end

