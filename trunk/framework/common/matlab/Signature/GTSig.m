classdef GTSig < SignatureAPI

    properties
        unit_feat
    end
    
    methods (Static)
        function obj = GTSig(detector, descriptor, unit_feat, norm)
            obj = obj@SignatureAPI();
            
            obj.detector = detector;
            obj.descriptor = descriptor;
            obj.unit_feat = unit_feat;
            obj.sig_size = length(unit_feat);
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Learn training signatures
        function obj = learn(obj, Ipaths)
            pg = ProgressBar('Learning training signatures', '');
            
            % Compute feature points
            pg.setCaption('Computing feature points...');
            feat = obj.compute_features(obj.detector, Ipaths, pg, 0, 1);

            % Compute descriptors
            pg.setCaption('Computing descriptors...');
            descr = obj.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, 0, 1);     
            
            
        end
        
        %------------------------------------------------------------------
        % Return the signature of the Images
        function sigs = get_signatures(obj, Ipaths, pg, offset, scale)   
            % Compute feature points
            pg.setCaption('Computing feature points...');
            feat = obj.compute_features(obj.detector, Ipaths, pg, offset, scale/2);

            % Compute descriptors
            pg.setCaption('Computing descriptors...');
            descr = obj.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, offset+scale/2, scale/2);
            
            n_img = length(Ipaths);
            n_unit_feat = length(obj.unit_feat);                
            sigs = zeros(n_img, n_unit_feat);
            
            % Computes signatures
            for i = 1:n_img
                bb = get_bb_info(Ipaths{i});
                for j = 1:n_unit_feat                    
                    sigs(i,j) = fit_unit_feat(feat{k}, descr{k}, bb(2:5), obj.unit_feat(j));
                end
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = 'Growing Tree signatures';
        end
        function str = toFileName(obj)
            str = 'GTSig';
        end
        function str = toName(obj)        
            str = 'GTSig';
        end
    end
    
end

