classdef SignatureAPI < handle
    % Signature Interface 
    properties (SetAccess = protected)
        detector
        descriptor
        sig_size      % Dimensionnality of the signature
        train_sigs    % Training signatures
        norm          % Norm used to normalize signatures               
        version       % API version
    end
    
    methods
        function obj = SignatureAPI()
            obj.version = SignatureAPI.current_version();
        end
        
        % Learn the training set signatures
        learn(obj, Ipaths)
        
        % Return the signature of the Images
        sigs = get_signatures(obj, Ipaths, pg, offset, scale)        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function version = current_version()
            version = 2;
        end
        
        %------------------------------------------------------------------
        function obj = loadobj(a)
            if isempty(a.version)
                a.train_sigs = a.train_sigs';
            elseif a.version < 2
                a.train_sigs = a.train_sigs';
            end
            obj = a;
            obj.version = SignatureAPI.current_version();
        end
        
        %------------------------------------------------------------------
        % Return one feature per line: (X,Y,radius,scale,?,zone)
        function feat = compute_features(detector, Ipaths, pg, offset, scale)
            global HASH_PATH USE_PARALLEL TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, detector.toFileName()));
                        
            if exist(file,'file') == 2
                load(file,'feat');
            end
            if exist('feat', 'var') == 1
                write_log(sprintf('Features loaded from cache: %s.\n', file));
            else    
                if USE_PARALLEL
                    if nargin >= 5
                        feat = run_in_parallel('DetectorAPI.run_parallel', detector, Ipaths, 0, 0, pg, offset, scale);
                    else
                        feat = run_in_parallel('DetectorAPI.run_parallel', detector, Ipaths, 0, 0);
                    end
                else
                    n_img = size(Ipaths,1);
                    feat = cell(n_img, 1);
                    for k=1:n_img
                        if nargin >= 5
                            pg.progress(offset+scale*k/n_img);
                        end
                        feat{k} = detector.get_features(Ipaths{k});
                    end
                end
                save(file, 'feat');
            end
        end
        
        %------------------------------------------------------------------
        function descr = compute_descriptors(detector, descriptor, Ipaths, feat, pg, offset, scale)
            global HASH_PATH USE_PARALLEL TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s-%s.mat',HASH_PATH,descriptor.toFileName(),detector.toFileName()));
            if exist(file,'file') == 2
                load(file,'descr');
            end
            if exist('descr', 'var') == 1
                write_log(sprintf('Descriptors loaded from cache: %s.\n', file));                
            else    
                n_img = size(Ipaths,1);
                if ~detector.is_rotation_invariant()
                    for k=1:n_img
                        f = feat{k};
                        f(:,4:5) = 0;
                        feat{k} = f;
                    end
                end
                
                if USE_PARALLEL
                    if nargin >= 7
                        descr = run_in_parallel('DescriptorAPI.run_parallel', descriptor, horzcat(Ipaths,feat), 0, 0, pg, offset, scale);
                    else
                        descr = run_in_parallel('DescriptorAPI.run_parallel', descriptor, horzcat(Ipaths,feat), 0, 0);
                    end
                else
                    descr = cell(n_img, 1);
                    for k=1:n_img
                        if nargin >= 7
                            pg.progress(offset+scale*k/n_img);
                        end
                        descr{k} = descriptor.get_descriptors(Ipaths{k}, feat{k});
                    end
                end      
                save(file, 'descr', '-v7.3');
            end
        end
        
        %------------------------------------------------------------------
        % Load the bounding boxes of an image
        function box = get_bounding_box(zone, Ipath)
            zone = abs(zone);
            
            [d f] = fileparts(Ipath);
            f = fullfile(d, sprintf('%s.info', f));
            bb = load(f,'-ascii');
            if size(bb,1) < zone
                box = [1 1 0 0];
            else
                box = bb(zone, 2:end);
            end
            
        end        
        
        %------------------------------------------------------------------
        function [feat descr] = filter_by_zone(zone, Ipath, feat, descr)
            if zone
                box = SignatureAPI.get_bounding_box(zone, Ipath);
                
                is_inside = (feat(:,1) >= box(1) & feat(:,1) <= box(3) & feat(:,2) >= box(2) & feat(:,2) <= box(4));
                if zone>0
                    feat = feat(is_inside,:);
                    descr = descr(is_inside,:);
                else
                    feat = feat(~is_inside,:);
                    descr = descr(~is_inside,:);
                end
            end
        end
    end    
end

