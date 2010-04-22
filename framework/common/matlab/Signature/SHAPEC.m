classdef SHAPEC < SignatureAPI
    % Shape context
    properties % (SetAccess = protected, GetAccess = protected)
        K
        kmeans
        scale       % scale of the shape context
        num_R_bins  % Number of radial bins
        num_A_bins  % Number of angle bins
        centers
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function sigs = compute_signatures(obj, centers, feat, descr, pg, offset, scale)
            global USE_PARALLEL;
           
            if USE_PARALLEL
                common = struct('centers', centers, 'sig_size', obj.channel_sig_size, 'scale', obj.scale, 'num_R_bins', obj.num_R_bins, 'num_A_bins', obj.num_A_bins);
                para = struct('feat', feat, 'descr', descr);
                sigs = run_in_parallel('SHAPEC.parallel_signatures', common, para, 0, 0, pg, offset, scale);
            else
                n_img = size(Ipath, 1);
                sigs = zeros(n_img, obj.channel_sig_size);
                for k=1:n_img
                    pg.progress(offset+scale*k/n_img);
                    sigs(k, :) = obj.sig_from_feat_descr(centers, feat{k}, descr{k}, obj.scale, obj.num_R_bins, obj.num_A_bins);
                end    
            end
            
            sigs = obj.norm.normalize(sigs);
        end   
    end
    
    methods (Static = true)         
        %------------------------------------------------------------------
        function sig = parallel_signatures(common, args)
            tid = task_open();
            
            n_img = size(args, 1);
            sig = zeros(n_img, common.sig_size);
            for k=1:n_img
                task_progress(tid, k/n_img);
                sig(k, :) = SHAPEC.sig_from_feat_descr(common.centers, args(k).feat, args(k).descr, common.scale, common.num_R_bins, common.num_A_bins);
            end  
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function sig = sig_from_feat_descr(centers, feat, descr, scale, num_R_bins, num_A_bins)
            d = dist2(centers, descr);
            m = (d == repmat(min(d), size(d,1), 1));
            
            n_feat = size(feat, 1);
            n_centers = size(centers, 1);
            sigs = cell(n_centers, 1);
            
            for k = 1:n_centers
                sigs{k} = zeros(1, n_centers*num_R_bins*num_A_bins);
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
                R = floor(log2(R/scale))+1;
                R(k) = 1;
                A = floor((pi-A)*num_A_bins/(2*pi)) + 1;
                
                % Build histogram
                sig = zeros(1, n_centers*num_R_bins*num_A_bins*n_centers);
                for i = 1:num_R_bins
                    for j = 1:num_A_bins                    
                        I = (R == i) & (A == j);
                        n = n_centers*(j - 1 + num_A_bins * (i - 1 + num_R_bins * (k - 1)));
                        sig((n+1):(n+n_centers)) = sum(m(:, I), 2)';
                    end
                end
                
                t = find(m(:,k),1);
                sigs{t} = sigs{t} + sig;
            end
            sig = cat(2, sigs{:});               
        end   
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = SHAPEC(channels, K, norm, scale, num_R_bins, num_A_bins, kmeans_lib, maxiter)          
            if nargin < 4
                scale = 5;
            end
            if nargin < 5
                num_R_bins = 5;
            end
            if nargin < 6
                num_A_bins = 8;
            end                
            if nargin < 7
                kmeans_lib = 'cpp';
            end
            if nargin < 8
                maxiter = 200;
            end        
            
            obj.K = K;
            obj.scale = scale;
            obj.num_R_bins = num_R_bins;
            obj.num_A_bins = num_A_bins;
            obj.kmeans = Kmeans(K, kmeans_lib, maxiter);
            obj.channels = channels;
            obj.channel_sig_size = K*K*num_R_bins*num_A_bins;  
            obj.total_sig_size = obj.channels.number()*obj.channel_sig_size;
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Eventually learn the training set signature
        function obj = learn(obj, Ipaths)          
            global HASH_PATH TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.toFileName()));
            
            if exist(file,'file') == 2
                load(file,'centers','train_sigs');
                obj.centers = centers;
                obj.train_sigs = train_sigs;
                write_log(sprintf('Signature loaded from cache: %s.\n', file));
            else    
                pg = ProgressBar('Learning training signatures', '');
                n_channels = obj.channels.number;
                obj.centers = cell(n_channels, 1);
                sigs = cell(n_channels, 1);

                obj.channels.init();
                last_detector = 0;

                feature_progress_frac = 0.15/obj.channels.number;
                descrip_progress_frac = 0.15/obj.channels.number;
                k_means_progress_frac = 0.65/obj.channels.number;
                sigs_progress_frac =    0.05/obj.channels.number;

                while(not(obj.channels.eoc()))
                    progress_value = (obj.channels.channel_id()-1)/obj.channels.number;
                    progress_text = sprintf('Channel %d on %d: ', obj.channels.channel_id(),obj.channels.number);

                    if last_detector ~= obj.channels.get_detector_id()
                        % Compute feature points
                        pg.setCaption([progress_text 'Computing feature points...']);
                        feat = obj.compute_features(obj.channels.get_detector(), Ipaths, pg, progress_value, feature_progress_frac);
                        last_detector = obj.channels.get_detector_id();
                        progress_value = progress_value + feature_progress_frac;
                    end

                    % Compute descriptors
                    pg.setCaption([progress_text 'Computing descriptors...']);
                    descr = obj.compute_descriptors(obj.channels.get_detector(), obj.channels.get_descriptor(), Ipaths, feat, pg, progress_value, descrip_progress_frac);           
                    progress_value = progress_value + descrip_progress_frac;

                    % Compute visual vocabulary
                    d = cat(1, descr{:});
                    pg.setCaption(sprintf('%sComputing BOF... (found %d descriptors)',progress_text,size(d,1)));                 
                    center_file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.KmeanstoFileName(obj.channels.channel_id())));
                    obj.centers{obj.channels.channel_id()} = obj.kmeans.do_kmeans(d, center_file);
                    progress_value = progress_value + k_means_progress_frac;

                    % Compute signature for this channel
                    pg.setCaption([progress_text 'Computing signatures...']);
                    sigs{obj.channels.channel_id()} = obj.compute_signatures(obj.centers{obj.channels.channel_id()}, feat, descr, pg, progress_value, sigs_progress_frac);

                    % Next channel
                    obj.channels.next();
                end

                obj.train_sigs = cat(2, sigs{:});
                % Each channel is already normalized, renormalize the
                % overall in case of multi-channel
                if obj.channels.number > 1
                    obj.train_sigs = obj.norm.normalize(obj.train_sigs);
                end
                
                train_sigs = obj.train_sigs;
                centers = obj.centers;
                save(file,'-v7.3','centers','train_sigs');
                pg.close();
            end
        end
        
        %------------------------------------------------------------------
        % Return the signature of the Images
        function sigs = get_signatures(obj, Ipaths, pg, offset, scale)
            if nargin<5
                pg = ProgressBar('Computing signatures', '', true);
            end
            n_channels = obj.channels.number;
            sigs = cell(1, n_channels);
           
            obj.channels.init();
            last_detector = 0;
            
            feature_progress_frac = scale*0.45/obj.channels.number;
            descrip_progress_frac = scale*0.45/obj.channels.number;
            sigs_progress_frac =    scale*0.10/obj.channels.number;
            
            while(~obj.channels.eoc())
                progress_value = offset + scale*(obj.channels.channel_id()-1)/obj.channels.number;
                progress_text = sprintf('Channel %d on %d: ', obj.channels.channel_id(),obj.channels.number);
                
                if last_detector ~= obj.channels.get_detector_id()
                    % Compute feature points
                    pg.setCaption([progress_text 'Computing feature points...']);
                    feat = obj.compute_features(obj.channels.get_detector(), Ipaths, pg, progress_value, feature_progress_frac);
                    last_detector = obj.channels.get_detector_id();
                    progress_value = progress_value + feature_progress_frac;
                end

                % Compute descriptors
                pg.setCaption([progress_text 'Computing descriptors...']);
                descr = obj.compute_descriptors(obj.channels.get_detector(), obj.channels.get_descriptor(), Ipaths, feat, pg, progress_value, descrip_progress_frac); 
                progress_value = progress_value + descrip_progress_frac;
               
                % Compute signature for this channel
                pg.setCaption([progress_text 'Computing signatures...']);
                obj.L(:,3) = obj.L_Wchan(:, obj.channels.channel_id());
                sigs{obj.channels.channel_id()} = obj.compute_signatures(obj.centers{obj.channels.channel_id()}, feat, descr, pg, progress_value, sigs_progress_frac);
                
                % Next channel
                obj.channels.next();
            end
            sigs = cat(2, sigs{:});            
            
            if nargin<5
                pg.close();
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)          
            str = [sprintf('Signature: Shape context (K = %d, histogram normalization: %s, K-means library: %s)\n', obj.K, obj.norm.toString(), obj.kmeans.get_lib()) obj.channels.toString()];
        end
        function str = toFileName(obj)
            str = sprintf('SHC[%s-%d-%s]-%s', obj.kmeans.get_lib(), obj.K, obj.norm.toFileName(), obj.channels.toFileName());
        end
        function str = KmeanstoFileName(obj, numChannel)
            str = sprintf('Kmeans[%s-%d]-C(%d)-%s', obj.kmeans.get_lib(), obj.K, numChannel, obj.channels.toFileName());
        end
        function str = toName(obj)
            str = sprintf('SHC(%d)', obj.K);
        end
    end
end

