classdef Channels < handle
    properties (SetAccess = protected)
        detectors       % Array of detectors
        descriptors     % Array of descriptors
        cur_detect      % Current detector
        cur_descrip     % Current descriptor
        n_detector      % Number of detectors
        n_descriptor    % Number of descriptors
        number          % Number of channels        
    end
        
    methods
        function obj = Channels(detectors, descriptors)
            obj.n_detector = length(detectors);
            obj.n_descriptor = length(descriptors);
            obj.number = obj.n_descriptor*obj.n_detector;
            
            if obj.n_detector == 0 || obj.n_descriptor == 0
                throw(MException('','There should be at least one detector and one descriptor to build a channel.'));
            end
            
            obj.detectors = detectors;
            obj.descriptors = descriptors;
        end
        
        function obj = init(obj)
            obj.cur_detect = 1;
            obj.cur_descrip = 1;          
        end      
        
        function obj = next(obj)
            if obj.cur_descrip == obj.n_descriptor
                obj.cur_detect = obj.cur_detect + 1;
                obj.cur_descrip = 1;
            else
                obj.cur_descrip = obj.cur_descrip + 1;
            end
        end 
        
        function end_of_channel = eoc(obj)
            end_of_channel = obj.cur_detect > obj.n_detector;
        end       
        
        function detector = get_detector(obj)
            detector = obj.detectors{obj.cur_detect};
        end
        
        function descriptor = get_descriptor(obj)
            descriptor = obj.descriptors{obj.cur_descrip};
        end
        
        function id = channel_id(obj)
            id = (obj.cur_detect-1)*obj.n_descriptor + obj.cur_descrip;
        end
        
        function detector_id = get_detector_id(obj)
            detector_id = obj.cur_detect;
        end
        
        function descriptor_id = get_descriptor_id(obj)
            descriptor_id = obj.cur_descrip;
        end   
        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            chan_str = cell(obj.number+1, 1);
            chan_str{1} = sprintf('Channels:\n');
            for i=1:obj.n_detector
                for j=1:obj.n_descriptor
                    chan_str{1+(i-1)*obj.n_descriptor + j} = sprintf('  (%s) x (%s)\n', obj.detectors{i}.toString(), obj.descriptors{j}.toString());
                end
            end
            str = [chan_str{:}];
        end
        function str = toFileName(obj)
            if obj.n_detector > 1
                detect_str = cell(obj.n_detector, 1);
                for i=1:obj.n_detector
                    detect_str{i} = obj.detectors{i}.toFileName();
                    if i<obj.n_detector
                        detect_str{i} = [detect_str{i} '+'];
                    end
                end
                detect_str = sprintf('(%s)', [detect_str{:}]);
            else
                detect_str = obj.detectors{1}.toFileName();
            end
            
            if obj.n_descriptor > 1
                descrip_str = cell(obj.n_descriptor, 1);
                for i=1:obj.n_descriptor
                    descrip_str{i} = obj.descriptors{i}.toFileName();
                    if i<obj.n_descriptor
                        descrip_str{i} = [descrip_str{i} '+'];
                    end
                end 
                descrip_str = sprintf('(%s)', [descrip_str{:}]);
            else
                descrip_str = obj.descriptors{1}.toFileName();
            end
                        
            str = [detect_str 'x' descrip_str];
        end
    end
    
end

