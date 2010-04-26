classdef BOF < SignatureAPI
    % Bag of features
    properties (SetAccess = protected, GetAccess = protected)
        K     
        L          % for spatial pyramid
        L_Wchan    % weight for each channel
        L_Wchan_cv % remember if weight estimation was performed automaticaly
        centers   
        kmeans
    end
    
    % These properties are kept for compatibily reasons
    properties (SetAccess = protected, GetAccess = protected)    
        maxiter
        kmeans_lib
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function sigs = compute_signatures(obj, centers, feat, descr, Ipath, pg, offset, scale)
            global USE_PARALLEL;
           
            if USE_PARALLEL
                sigs = run_in_parallel('BOF.parallel_signatures', struct('centers', centers, 'sig_size', obj.channel_sig_size, 'L', obj.L), struct('feat', feat, 'descr', descr, 'Ipath', Ipath), 0, 0, pg, offset, scale);
            else
                n_img = size(Ipath, 1);
                sigs = zeros(n_img, obj.channel_sig_size);
                for k=1:n_img
                    pg.progress(offset+scale*k/n_img);

                    sigs(k, :) = obj.sig_from_feat_descr(obj.L, centers, feat{k}, descr{k}, Ipath{k});
                end    
            end
            
            % Looks for the grid with null weight and set it to the
            % average chi² distance between features
            z_index = find(obj.L(:,3) == 0);
            for k=1:length(z_index)
                s = sigs(:, obj.L(z_index(k),4):obj.L(z_index(k),5));
                n_sigs = size(s, 1);
                dist = 0;
                for i=1:n_sigs
                    for j=(i+1):n_sigs
                        dist = dist + chi2(s(i,:), s(j,:));
                    end
                end    
                % Average distance
                obj.L(z_index(k), 3) = 1 / (dist / (n_sigs*(n_sigs-1)/2));
                sigs(:, obj.L(z_index(k),4):obj.L(z_index(k),5)) = s * obj.L(z_index(k), 3);
            end

            sigs = obj.norm.normalize(sigs);
        end   
    end
    
    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if ~isa(obj.kmeans, 'Kmeans')
                obj.kmeans = Kmeans(obj.K, obj.kmeans_lib, obj.maxiter);                
            end
            if isempty(obj.L)
                obj.L = [1 1 1];
            elseif isscalar(obj.L)
                obj.L = floor(obj.L);
                levels = (0:obj.L)';
                grid = [2.^levels, 2.^levels, 1./2.^(obj.L-levels+1)];
                grid(1,3) = 1/2^obj.L;
                obj.L = grid;
            end
            if size(obj.L_Wchan,1) ~= size(obj.L,1)
                obj.L_Wchan = repmat(obj.L(:,3), 1, obj.channels.number());
            end
            if ~isfield(a, 'L_Wchan_cv')
                obj.L_Wchan_cv = ones(size(obj.L_Wchan,1),1);
            end            
            if obj.L_Wchan(1,1) == 1/2^(size(obj.L_Wchan,1)-1);
                obj.L_Wchan_cv = zeros(size(obj.L_Wchan,1),1);
            end            
        end        
         
        %------------------------------------------------------------------
        function sig = parallel_signatures(common, args)
            tid = task_open();
            
            n_img = size(args, 1);
            sig = zeros(n_img, common.sig_size);
            for k=1:n_img
                task_progress(tid, k/n_img);
                sig(k, :) = BOF.sig_from_feat_descr(common.L, common.centers, args(k).feat, args(k).descr, args(k).Ipath);
            end  
            
            task_close(tid);
        end
        
        %------------------------------------------------------------------
        function sig = sig_from_feat_descr(L, centers, feat, descr, Ipath)
            if size(descr, 1) == 0
                sig = zeros(1,size(centers,1));
            else
                d = dist2(centers, descr);
                m = (d == repmat(min(d), size(d,1), 1));  
                
                info = imfinfo(Ipath);
                w = info.Width;
                h = info.Height;                   
                X = (feat(:,1)-1)/w;
                Y = (feat(:,2)-1)/h;
                
                n_grid = size(L, 1);             
                sig = cell(n_grid,1);
                for i = 1:n_grid
                    n_bin = L(i,1)*L(i,2);
                    s = cell(n_bin,1);
                    I = floor(X*L(i,1)) * L(i,2) + floor(Y*L(i,2)) + 1;
                    for j = 1:n_bin
                        s{j} = sum(m(:,I == j), 2);
                    end
                    if L(i,3) ~= 0 && L(i,3) ~= 1
                        sig{i} = cat(1, s{:}) * L(i,3);
                    else
                        sig{i} = cat(1, s{:});
                    end
                end
                sig = cat(1,sig{:})';
            end
        end        
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = BOF(channels, K, norm, L, kmeans_lib, maxiter)
            if nargin < 4 || isempty(L)
                L = [1 1 1];
            end              
            if nargin < 5
                kmeans_lib = 'cpp';
            end
            if nargin < 6
                maxiter = 200;
            end        
            
            L(:,1:2) = floor(L(:,1:2));
            
            obj.K = K;
            obj.kmeans = Kmeans(K, kmeans_lib, maxiter);
            obj.channels = channels;
            n_cells = sum(L(:,1).*L(:,2));
            end_index = cumsum(L(:,1).*L(:,2));
            beg_index = [0; end_index(1:(end-1))];
            obj.L_Wchan = repmat(L(:,3), 1, channels.number());
            obj.L_Wchan_cv = L(:,3) == 0;
            obj.L = [L (beg_index*obj.K+1) (end_index*obj.K)];
            obj.channel_sig_size = K*n_cells;   % See Lazebnik, Spatial Pyramid Matching
            obj.total_sig_size = obj.channels.number()*obj.channel_sig_size;
            obj.norm = norm;
        end
        
        %------------------------------------------------------------------
        % Eventually learn the training set signature
        function obj = learn(obj, Ipaths)          
            global HASH_PATH TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.toFileName()));
            
            if exist(file,'file') == 2
                write_log(sprintf('Loading signature from cache: %s.\n', file));
                load(file,'centers','train_sigs');
                obj.centers = centers;
                obj.train_sigs = train_sigs;
                write_log(sprintf('Loaded.\n'));
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
                    num_descr = 0;
                    for i = 1:size(descr,1)
                        num_descr = num_descr + size(descr{i}, 1);
                    end
                    pg.setCaption(sprintf('%sComputing BOF... (found %d descriptors)',progress_text, num_descr));                                       
                    center_file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,obj.KmeanstoFileName(obj.channels.channel_id())));
                    obj.prepare_kmeans(cat(1, descr{:})');
                    obj.centers{obj.channels.channel_id()} = obj.kmeans.do_kmeans(center_file);
                    progress_value = progress_value + k_means_progress_frac;

                    % Compute signature for this channel
                    pg.setCaption([progress_text 'Computing signatures...']);
                    obj.L(:,3) = obj.L_Wchan(:, obj.channels.channel_id());
                    sigs{obj.channels.channel_id()} = obj.compute_signatures(obj.centers{obj.channels.channel_id()}, feat, descr, Ipaths, pg, progress_value, sigs_progress_frac);
                    obj.L_Wchan(:, obj.channels.channel_id()) = obj.L(:,3);

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
                save(file,'centers','train_sigs');
                pg.close();
            end
        end
        
        %------------------------------------------------------------------
        % Return the signature of the Images
        function sigs = get_signatures(obj, Ipaths, pg, offset, scale)
            if nargin<3
                pg = ProgressBar('Computing signatures', '', true);
                offset = 0;
                scale = 1;
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
                sigs{obj.channels.channel_id()} = obj.compute_signatures(obj.centers{obj.channels.channel_id()}, feat, descr, Ipaths, pg, progress_value, sigs_progress_frac);
                
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
        function str = get_pyramid(obj)
            n_grid = size(obj.L, 1);
            str = cell(1,n_grid);
            for i = 1:n_grid
                if obj.L_Wchan_cv(i)
                    w = '?';
                else
                    w = num2str(obj.L(i,3));
                end
                str{i} = sprintf('%dx%dx%s', obj.L(i,1), obj.L(i,2), w);
                if i ~= n_grid
                    str{i} = [str{i} '+'];
                end
            end
            str = cat(2, str{:});
        end
        function str = toString(obj)
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = [sprintf('Signature: Bag of features (K = %d, histogram normalization: %s, K-means library: %s)\n', obj.K, obj.norm.toString(), obj.kmeans.get_lib()) obj.channels.toString()];
            else
                str = [sprintf('Signature: Spatial pyramid (K = %d, L = %s, histogram normalization: %s, K-means library: %s)\n', obj.K, obj.get_pyramid(), obj.norm.toString(), obj.kmeans.get_lib()) obj.channels.toString()];
            end
        end
        function str = toFileName(obj)
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('BOF[%s-%d-%s]-%s', obj.kmeans.get_lib(), obj.K, obj.norm.toFileName(), obj.channels.toFileName());
            else
                str = sprintf('PYR[%s-%d-%s-%s]-%s', obj.kmeans.get_lib(), obj.K, obj.get_pyramid(), obj.norm.toFileName(), obj.channels.toFileName());
            end
        end
        function str = KmeanstoFileName(obj, numChannel)
            str = sprintf('Kmeans[%s-%d]-C(%d)-%s', obj.kmeans.get_lib(), obj.K, numChannel, obj.channels.toFileName());
        end
        function str = toName(obj)
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('BOF(%d)', obj.K);
            else
                str = sprintf('PYR(%s)-BOF(%d)', obj.get_pyramid(), obj.K);
            end
        end
    end
end

