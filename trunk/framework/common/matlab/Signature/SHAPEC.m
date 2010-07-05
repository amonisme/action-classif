classdef SHAPEC < SignatureAPI
    % Shape context
    properties % (SetAccess = protected, GetAccess = protected)
        K
        zone
        centers
        kmeans
        scale       % scale of the shape context
        num_R_bins  % Number of radial bins
        num_A_bins  % Number of angle bins        
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function sigs = compute_signatures(obj, feat, descr, pg, offset, scale)
            global USE_PARALLEL;
            
            if USE_PARALLEL
                common = struct('centers', obj.centers, 'sig_size', obj.sig_size, 'scale', obj.scale, 'num_R_bins', obj.num_R_bins, 'num_A_bins', obj.num_A_bins);
                para = struct('feat', feat, 'descr', descr);
                sigs = run_in_parallel('SHAPEC.parallel_signatures', common, para, 0, 0, pg, offset, scale);
            else
                n_img = length(feat);
                sigs = sparse(obj.sig_size, n_img);
                for k=1:n_img
                    pg.progress(offset+scale*k/n_img);
                    sigs(:, k) = obj.sig_from_feat_descr(obj.centers, feat{k}, descr{k}, obj.scale, obj.num_R_bins, obj.num_A_bins);
                end
            end
            
            sigs = obj.norm.normalize(sigs);
        end
    end
    
    methods (Static = true)
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
        function sig = parallel_signatures(common, args)
            tid = task_open();
            
            n_img = size(args, 1);
            sig = sparse(common.sig_size, n_img);
            for k=1:n_img
                task_progress(tid, k/n_img);
                sig(:, k) = SHAPEC.sig_from_feat_descr(common.centers, args(k).feat, args(k).descr, common.scale, common.num_R_bins, common.num_A_bins);
            end
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function sig = sig_from_feat_descr(centers, feat, descr, scale, num_R_bins, num_A_bins)
            d = dist2(centers, descr);
            m = (d == repmat(min(d), size(d,1), 1));
            
            n_feat = size(feat, 1);
            n_centers = size(centers, 1);
            sigs = cell(1, n_centers);
            
            for k = 1:n_centers
                sigs{k} = sparse((num_R_bins*num_A_bins+1)*n_centers, 1);
            end
            
            for k = 1:n_feat
                % Coordinates in feature space
                C = [(feat(:,1) - feat(k,1)), (feat(:,2) - feat(k,2))];
                
                % Normalize with the feature scale
                C = C / feat(k,3);
                
                % Normalize with the feature angle
                a = feat(k,4);
                if a ~= 0
                    R = [cos(a) sin(a); -sin(a) cos(a)];
                    C = (R * (C'))';
                end
                
                % Compute radius and angle
                R = sqrt(sum(C.*C, 2));
                A = angle(C(:,1)+1i*C(:,2));
                
                % Discretize into bins
                R = floor(log2(ceil(R/scale)))+1;
                R(k) = 0;
                A = floor((pi-A)*num_A_bins/(2*pi)) + 1;             
                
                % Build histogram
                sig = sparse((num_R_bins*num_A_bins+1)*n_centers, 1);
                for i = 0:num_R_bins
                    if i==0
                        I = (R == i);
                        sig(1:n_centers) = sum(m(:, I), 2);
                    else
                        for j = 1:num_A_bins
                            I = (R == i) & (A == j);
                            type_bin = (i-1) * num_A_bins + j;
                            n = type_bin * n_centers;
                            sig((n+1):(n+n_centers)) = sum(m(:, I), 2);
                        end
                    end
                end
                
                t = find(m(:,k),1);
                sigs{t} = sigs{t} + sig;
            end
            sig = cat(1, sigs{:});            
        end
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SHAPEC(detector, descriptor, K, norm, zone, scale, num_R_bins, num_A_bins, kmeans_lib, maxiter)
            if nargin < 5
                zone = 0;
            end            
            if nargin < 6
                scale = 14;
            end
            if nargin < 7
                num_R_bins = 5;
            end
            if nargin < 8
                num_A_bins = 8;
            end
            if nargin < 9
                kmeans_lib = 'c';
            end
            if nargin < 10
                maxiter = 200;
            end
            
            obj = obj@SignatureAPI();
            obj.detector = detector;
            obj.descriptor = descriptor;
            obj.K = K;
            obj.zone = zone;
            obj.scale = scale;
            obj.num_R_bins = num_R_bins;
            obj.num_A_bins = num_A_bins;
            obj.kmeans = Kmeans(K, kmeans_lib, maxiter);
            obj.sig_size = K*K*(num_R_bins*num_A_bins+1);
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Learn the training set signature
        function obj = learn(obj, Ipaths)
            global HASH_PATH TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.toFileName()));
            
            if exist(file,'file') == 2
                write_log(sprintf('Loading signature from cache: %s.\n', file));
                load(file,'centers','train_sigs');
                obj.centers = centers;
                if size(train_sigs,1) == length(Ipaths) && size(train_sigs,2) == obj.sig_size
                    obj.train_sigs = train_sigs';
                else
                    obj.train_sigs = train_sigs;
                end
                write_log(sprintf('Loaded.\n'));
            else
                pg = ProgressBar('Learning training signatures', '');
                progress_value = 0;
                
                feature_progress_frac = 0.05;
                descrip_progress_frac = 0.05;
                k_means_progress_frac = 0.50;
                sigs_progress_frac =    0.40;
                
                % Compute feature points
                pg.setCaption('Computing feature points...');
                feat = obj.compute_features(obj.detector, Ipaths, pg, 0, feature_progress_frac);
                progress_value = progress_value + feature_progress_frac;
                
                % Compute descriptors
                pg.setCaption('Computing descriptors...');
                descr = obj.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, progress_value, descrip_progress_frac);
                progress_value = progress_value + descrip_progress_frac;
                
                % Filter features according to the bounding box
                for i=1:length(Ipaths)
                    [f d] = SignatureAPI.filter_by_zone(obj.zone, Ipaths{i}, feat{i}, descr{i});
                    feat{i} = f;
                    descr{i} = d;
                end
                
                % Compute visual vocabulary
                n = obj.kmeans.prepare_kmeans(descr);
                pg.setCaption(sprintf('Computing BOF... (found %d descriptors)', n));
                obj.centers = obj.kmeans.do_kmeans(...
                    fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.KmeanstoFileName())));
                progress_value = progress_value + k_means_progress_frac;
                
                % Compute signature
                pg.setCaption('Computing signatures...');
                obj.train_sigs = obj.compute_signatures(feat, descr, pg, progress_value, sigs_progress_frac);
                
                train_sigs = obj.train_sigs;
                centers = obj.centers;
                save(file,'centers','train_sigs');
                pg.close();
            end
        end
        
        %------------------------------------------------------------------
        % Return the signature of the Images
        function sigs = get_signatures(obj, Ipaths, pg, offset, scale)
            global HASH_PATH TEMP_DIR;
            file = fullfile(TEMP_DIR, sprintf('%s_SIG-%s.mat',HASH_PATH,obj.toFileName()));

            if exist(file,'file') == 2
                write_log(sprintf('Loading signature from cache: %s.\n', file));
                load(file,'sigs');
                if size(sigs,1) == length(Ipaths) && size(sigs,2) == obj.sig_size
                    sigs = sigs';                
                end                
            else 
                
                if nargin<3
                    pg = ProgressBar('Computing signatures', '', true);
                    offset = 0;
                    scale = 1;
                end          
            
                feature_progress_frac = 0.05;
                descrip_progress_frac = 0.05;
                sigs_progress_frac =    0.9;

                % Compute feature points
                pg.setCaption('Computing feature points...');
                feat = obj.compute_features(obj.detector, Ipaths, pg, offset, feature_progress_frac*scale);
                progress_value = feature_progress_frac;

                % Compute descriptors
                pg.setCaption('Computing descriptors...');
                descr = obj.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, offset + progress_value*scale, descrip_progress_frac*scale);
                progress_value = progress_value + descrip_progress_frac;

                % Compute signature for this channel
                pg.setCaption('Computing signatures...');
                sigs = obj.compute_signatures(feat, descr, pg, offset + progress_value*scale, sigs_progress_frac*scale);

                save(file,'sigs');

                if nargin<3
                    pg.close();
                end                
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            detect = obj.detector.toString();
            descrp = obj.descriptor.toString();
            n = obj.norm.toString();
            klib = obj.kmeans.get_lib();
            str = sprintf('Signature: Shape context (K = %d, histogram normalization: %s, K-means library: %s) of:\n$~~~~~~~~$%s of %s\n', obj.K, n, klib, descrp, detect);
        end
        function str = toFileName(obj)
            klib = obj.kmeans.get_lib();
            detect = obj.detector.toFileName();
            descrp = obj.descriptor.toFileName();
            n = obj.norm.toFileName();
            str = sprintf('SHC[%s-%d-%s-%s-%s]', klib, obj.K, n, descrp, detect);
        end
        function str = KmeanstoFileName(obj)
            klib = obj.kmeans.get_lib();
            detect = obj.detector.toFileName();
            descrp = obj.descriptor.toFileName();
            str = sprintf('Kmeans[%s-%d-%d-%s-%s]', klib, obj.K, obj.zone, descrp, detect);
        end
        function str = toName(obj)
            str = sprintf('SHC(%d)', obj.K);
        end
    end
end

