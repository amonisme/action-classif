classdef ClassifierAPI < handle
    % Classifier interface
    
    methods (Abstract)        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        [cv_res cv_dev] = learn(obj, root)
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        [Ipaths classes correct_label assigned_label score] = classify(obj, Ipaths, correct_label)   
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
        obj = save_to_temp(obj)
    end
    
end

