classdef BOF < SignatureAPI
    % Baf of features
    properties (SetAccess = protected, GetAccess = protected)
        K          % for K-means
        L          % for spatial pyramid
        centers   
        maxiter
        kmeans
        kmeans_lib
    end
    
    methods (Access = protected)
        %------------------------------------------------------------------
        function sigs = compute_signatures(obj, centers, feat, descr, Ipath, pg, offset, scale)
            global USE_PARALLEL;
           
            if USE_PARALLEL
                s = run_in_parallel('BOF.parallel_signatures', struct('centers', centers, 'sig_size', obj.channel_sig_size, 'L', obj.L), struct('feat', feat, 'descr', descr, 'Ipath', Ipath), 0, 0, pg, offset, scale);
            else
                n_img = size(Ipath, 1);
                s = zeros(n_img, obj.channel_sig_size);
                for k=1:n_img
                    pg.progress(offset+scale*k/n_img);
                    s(k, :) = obj.sig_from_feat_descr(obj.L, centers, feat{k}, descr{k}, Ipath{k});
                end    
            end
            sigs = obj.norm.normalize(s);
        end   
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function feat = compute_features(detector, Ipaths, pg, offset, scale)
            global HASH_PATH USE_PARALLEL TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s.mat',HASH_PATH,detector.toFileName()));
            
            if exist(file,'file') == 2
                load(file,'feat');
                write_log(sprintf('Features loaded from cache: %s.\n', file));
            else    
                if USE_PARALLEL 
                    feat = run_in_parallel('Detector_run_parallel', detector, Ipaths, 0, 0, pg, offset, scale);
                else
                    n_img = size(Ipaths,1);
                    feat = cell(n_img, 1);
                    for k=1:n_img
                        pg.progress(offset+scale*k/n_img);
                        feat{k} = detector.get_features(Ipaths{k});
                    end
                end
                save(file, 'feat');
            end
        end
        
        %------------------------------------------------------------------
        function descr = compute_descriptors(detector, descriptor, Ipaths, feat, pg, offset, scale)
            global HASH_PATH USE_PARALLEL TEMP_DIR;
            
            file = fullfile(TEMP_DIR, sprintf('%s_%s_%s.mat',HASH_PATH,descriptor.toFileName(),detector.toFileName()));
            
            if exist(file,'file') == 2
                load(file,'descr');
                write_log(sprintf('Descriptors loaded from cache: %s.\n', file));
            else    
                if USE_PARALLEL
                    descr = run_in_parallel('Descriptor_run_parallel', descriptor, horzcat(Ipaths,feat), 0, 0, pg, offset, scale);
                else
                    n_img = size(Ipaths,1);
                    descr = cell(n_img, 1);
                    for k=1:n_img
                        pg.progress(offset+scale*k/n_img);
                        descr{k} = descriptor.get_descriptors(Ipaths{k}, feat{k});
                    end
                end      
                save(file, 'descr');
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
                if L == 0   % Classic BOF
                    sig = sum(m, 2)';     
                else            % Spatial pyramid signature                   
                    % Get imgage size and normalize feature position
                    info = imfinfo(Ipath);
                    w = info.Width;
                    h = info.Height;                   
                    X = (feat(:,1)-1)/w;
                    Y = (feat(:,2)-1)/h;
                    
                    % Compute signature
                    sig = cell(L+1,1);
                    sig{1} = sum(m,2) / (2^L);                    
                    for i = 1:L
                        n_bin_side = 2^i;
                        n_bin = n_bin_side*n_bin_side;
                        s = cell(n_bin,1);
                        I = floor(X*n_bin_side) * n_bin_side + floor(Y*n_bin_side) + 1;
                        size(feat)
                        size(descr)
                        size(d)
                        size(m)
                        size(I)
                        for j = 1:n_bin
                            s{j} = sum(m(:,I == j), 2);
                        end
                        sig{i+1} = cat(1, s{:}) / (2^(L-i+1));
                    end
                    sig = cat(1,sig{:})';
                end
            end
        end        
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = BOF(channels, K, norm, L, kmeans_lib, maxiter)
            if(nargin < 4)
                L = 0;
            end              
            if(nargin < 5)
                kmeans_lib = 'cpp';
            end
            if(nargin < 6)
                maxiter = 200;
            end          
            
            
            obj.maxiter = maxiter;
            obj.kmeans_lib = kmeans_lib;           
            if(strcmpi(kmeans_lib, 'vlfeat'))
                obj.kmeans = @compute_kmeans_vlfeat;
            else
                if(strcmpi(kmeans_lib, 'vgg'))
                    obj.kmeans = @compute_kmeans_vgg;
                else
                    if(strcmpi(kmeans_lib, 'matlab'))
                        obj.kmeans = @compute_kmeans_matlab;
                    else
                        if(strcmpi(kmeans_lib, 'mex'))
                            obj.kmeans = @compute_kmeans_mex;
                        else
                            if(strcmpi(kmeans_lib, 'cpp'))
                                obj.kmeans = @compute_kmeans_mex;
                            else                            
                                throw(MException('',['Unknown library for computing K-means: "' kmeans_lib '".\nPossible values are: "vlfeat", "vgg", "matlab", "mex" and "cpp".\n']));
                            end
                        end
                    end
                end
            end
            obj.channels = channels;
            obj.K = floor(K);
            obj.L = floor(L);
            obj.channel_sig_size = K*(4^(L+1)-1)/3;   % See Lazebnik, Spatial Pyramid Matching
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
                    if exist(center_file,'file') == 2
                        load(center_file);
                    else
                        c = obj.kmeans(d, obj.K, obj.maxiter);    
                        save(center_file, 'c');
                    end
                    obj.centers{obj.channels.channel_id()} = c;
                    progress_value = progress_value + k_means_progress_frac;

                    % Compute signature for this channel
                    pg.setCaption([progress_text 'Computing signatures...']);
                    sigs{obj.channels.channel_id()} = obj.compute_signatures(c, feat, descr, Ipaths, pg, progress_value, sigs_progress_frac);

                    % Next channel
                    obj.channels.next();
                end

                obj.train_sigs = cat(2, sigs{:});
                train_sigs = obj.train_sigs;
                centers = obj.centers;
                save(file,'centers','train_sigs');
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
        function str = toString(obj)
            str = [sprintf('Signature: Bag of features (K = %d, histogram normalization: %s, K-means library: %s)\n', obj.K, obj.norm.toString(), obj.kmeans_lib) obj.channels.toString()];
        end
        function str = toFileName(obj)
            if isempty(obj.L)
                obj.L = 0;
            end
            str = sprintf('BOF[K(%d)-L(%d)-Norm(%s)-Kmeans(%s)]-OfChannels-%s', obj.K, obj.L, obj.norm.toFileName(), obj.kmeans_lib, obj.channels.toFileName());
        end
        function str = KmeanstoFileName(obj, numChannel)
            str = sprintf('Kmeans[K(%d)-L(%d)-Lib(%s)]-OfChannel(%d)-%s', obj.K, obj.L, obj.kmeans_lib, numChannel, obj.channels.toFileName());
        end
        function str = toName(obj)
            if obj.L == 0
                str = sprintf('BOF%d', obj.K);
            else
                str = sprintf('PYR%d-BOF%d', obj.L, obj.K);
            end
        end
    end
end

