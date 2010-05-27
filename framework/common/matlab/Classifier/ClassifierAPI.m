classdef ClassifierAPI < handle
    % Classifier interface
    
    properties (SetAccess = protected)        
        classes_names
        subclasses_names
        map_sub2sup
    end
    
    methods (Abstract)        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        [cv_res cv_dev] = learn(obj, root)
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        [Ipaths classes subclasses map_sub2sup correct_label assigned_label score] = classify(obj, Ipaths, correct_label)   
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
        obj = save_to_temp(obj)
    end
    
    methods (Access = protected)
        function store_names(obj, c_names, subc_names, map_sub2sup)
            if obj.is_identity(map_sub2sup)
                map_sub2sup = [];                
            end
            obj.classes_names = c_names;
            obj.subclasses_names = subc_names;
            obj.map_sub2sup = map_sub2sup;
        end
    end
    
    methods (Static)      
        function is_id = is_identity(map)
            is_id = 1;
            for i=1:length(map)
                if map(i) ~= i
                    is_id = 0;
                    break;
                end
            end
        end
    end
end

