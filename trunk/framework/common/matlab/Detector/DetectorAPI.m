classdef DetectorAPI
    % Abstract class for detectors    
    properties (SetAccess = protected, GetAccess = protected)
        rotInvariant   % 0 - scale invariant only, 1 - rotation and scale invariant
    end
    
    methods
        %------------------------------------------------------------------
        % True iif the detector is rotation invariant
        function ri = is_rotation_invariant(obj)
            ri = obj.rotInvariant;
        end
    end
       
    methods (Access = protected)
        %------------------------------------------------------------------
        % Constructor
        function obj = DetectorAPI(rotInvariant)  
            if strcmpi(rotInvariant, 'S')
                obj.rotInvariant = 0;
            else
                if strcmpi(rotInvariant, 'SR')
                    obj.rotInvariant = 1;
                else
                    throw(MException('',sprintf('Unknown invariance degree for detector: "%s".\nPossible values are: "S" (scale invariant) and "SR" (scale and rotation invariant).\n',rotInvariant)));
                end
            end            
        end
    end
    
    methods (Abstract)
        %------------------------------------------------------------------
        % Returns features of the image specified by Ipath (one per line)
        % Format: X Y scale angle 0
        feat = get_features(obj, Ipath)
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
end
