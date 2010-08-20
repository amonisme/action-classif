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
        learn(obj, images)
        
        % Return the signature of the Images
        sigs = get_signatures(obj, images, pg, offset, scale)        
        
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
        function feat = compute_features(detector, images, resize, pg, offset, scale)
            global HASH_PATH USE_PARALLEL TEMP_DIR;
            
            if nargin < 3
                resize = 0;
            end
            
            if resize
                file = fullfile(TEMP_DIR, sprintf('%s_R%d_%s.mat', HASH_PATH, resize, detector.toFileName()));
            else
                file = fullfile(TEMP_DIR, sprintf('%s_%s.mat', HASH_PATH, detector.toFileName()));
            end
                        
            if exist(file,'file') == 2
                load(file,'feat');
            end
            if exist('feat', 'var') == 1
                write_log(sprintf('Features loaded from cache: %s.\n', file));
            else    
                if USE_PARALLEL
                    n_img = length(images);
                    if resize
                        bboxes = cat(1, images(:).bndbox);
                        bb_width  = bboxes(:,3) - bboxes(:,1);
                        bb_height = bboxes(:,4) - bboxes(:,2);
                        scales = resize / max(bb_width, bb_height, 2);
                    else
                        scales = ones(n_img, 1);
                    end
                    args = cell(n_img, 2);
                    for i = 1:n_img
                        args{i,1} = image(i).path;
                        args{i,2} = scales;
                    end
                    if nargin >= 6
                        feat = run_in_parallel('DetectorAPI.run_parallel', detector, args, 0, 0, pg, offset, scale);
                    else
                        feat = run_in_parallel('DetectorAPI.run_parallel', detector, args, 0, 0);
                    end
                else
                    n_img = length(images);
                    feat = cell(n_img, 1);
                    for k=1:n_img
                        if nargin >= 6
                            pg.progress(offset+scale*k/n_img);
                        end
                        if resize
                            bb_width = images(k).bndbox(3)-images(k).bndbox(1);
                            bb_height = images(k).bndbox(4)-images(k).bndbox(2);
                            s = max(bb_width, bb_height);
                            scale = resize / s;
                        else
                            scale = 1;
                        end
                        feat{k} = detector.get_features(images(k).path, scale);
                    end
                end
                save(file, 'feat');
            end
        end
        
        %------------------------------------------------------------------
        function descr = compute_descriptors(detector, descriptor, images, feat, resize, pg, offset, scale)
            global HASH_PATH USE_PARALLEL TEMP_DIR;
            
            if nargin < 3
                resize = 0;
            end
            
            if resize
                file = fullfile(TEMP_DIR, sprintf('%s_R%d_%s-%s.mat', HASH_PATH, resize, descriptor.toFileName(), detector.toFileName()));
            else
                file = fullfile(TEMP_DIR, sprintf('%s_%s-%s.mat',HASH_PATH,descriptor.toFileName(),detector.toFileName()));
            end
            if exist(file,'file') == 2
                load(file,'descr');
            end
            if exist('descr', 'var') == 1
                write_log(sprintf('Descriptors loaded from cache: %s.\n', file));                
            else    
                n_img = length(images);
                if ~detector.is_rotation_invariant()
                    for k=1:n_img
                        f = feat{k};
                        f(:,4:5) = 0;
                        feat{k} = f;
                    end
                end
                
                if USE_PARALLEL
                    n_img = length(images);
                    if resize
                        bboxes = cat(1, images(:).bndbox);
                        bb_width  = bboxes(:,3) - bboxes(:,1);
                        bb_height = bboxes(:,4) - bboxes(:,2);
                        scales = resize / max(bb_width, bb_height, 2);
                    else
                        scales = ones(n_img, 1);
                    end
                    args = cell(n_img, 3);
                    for i = 1:n_img
                        args{i,1} = image(i).path;
                        args{i,2} = feat{i};
                        args{i,3} = scales;
                    end
                    if nargin >= 8
                        descr = run_in_parallel('DescriptorAPI.run_parallel', descriptor, args, 0, 0, pg, offset, scale);
                    else
                        descr = run_in_parallel('DescriptorAPI.run_parallel', descriptor, args, 0, 0);
                    end
                else
                    descr = cell(n_img, 1);
                    for k=1:n_img
                        if nargin >= 8
                            pg.progress(offset+scale*k/n_img);
                        end
                        if resize
                            bb_width = images(k).bndbox(3)-images(k).bndbox(1);
                            bb_height = images(k).bndbox(4)-images(k).bndbox(2);
                            s = max(bb_width, bb_height);
                            scale = resize / s;
                        else
                            scale = 1;
                        end                        
                        descr{k} = descriptor.get_descriptors(images(k).path, feat{k}, scale);
                    end
                end      
                save(file, 'descr', '-v7.3');
            end
        end     
        
        %------------------------------------------------------------------
        function [feat descr] = filter_by_zone(zone, image, feat, descr)
            if zone
                box = image.bndbox;
                
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

