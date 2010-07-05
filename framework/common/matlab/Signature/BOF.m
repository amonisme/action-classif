classdef BOF < SignatureAPI
    % Bag of features
    properties (SetAccess = protected)
        K     
        L          % grids for spatial pyramid
        L_cv
        centers   
        kmeans
        zone           % if zone is not null, the features should be inside the 'zone'th  bounding box if zone>0
                       %                                         or outside the '-zone'th bounding box if zone<0
                       % For zone>0 pyramid is restricted to the bb
    end
       
    methods (Access = protected)
        %------------------------------------------------------------------
        function sigs = compute_signatures(obj, feat, descr, Ipath, pg, offset, scale)
            global USE_PARALLEL;
           
            if USE_PARALLEL
                sigs = run_in_parallel('BOF.parallel_signatures', struct('centers', obj.centers, 'sig_size', obj.sig_size, 'L', obj.L, 'zone', obj.zone), struct('feat', feat, 'descr', descr, 'Ipath', Ipath), 0, 0, pg, offset, scale)';
            else
                n_img = size(Ipath, 1);
                sigs = zeros(obj.sig_size, n_img);
                for k=1:n_img
                    pg.progress(offset+scale*k/n_img);
                    sigs(:, k) = obj.sig_from_feat_descr(obj.L, obj.centers, feat{k}, descr{k}, Ipath{k}, obj.zone);
                end    
            end
            
            % Looks for the grid with null weight and set it to the
            % average chi² distance between features
            z_index = find(obj.L(:,3) == 0);
            for k=1:length(z_index)
                s = sigs(obj.L(z_index(k),4):obj.L(z_index(k),5), :);
                n_sigs = size(s, 2);
                dist = 0;
                for i=1:n_sigs
                    for j=(i+1):n_sigs
                        dist = dist + chi2(s(:,i), s(:,j));
                    end
                end    
                % Average distance
                obj.L(z_index(k), 3) = 1 / (dist / (n_sigs*(n_sigs-1)/2));
                sigs(obj.L(z_index(k),4):obj.L(z_index(k),5), :) = s * obj.L(z_index(k), 3);
            end         

            sigs = obj.norm.normalize(sigs);
        end   
    end
    
    methods (Static = true)    
        %------------------------------------------------------------------
        function obj = loadobj(a)
           obj = loadobj@SignatureAPI(a);
        end
            
        %------------------------------------------------------------------
        function sig = parallel_signatures(common, args)
            tid = task_open();
            
            n_img = size(args, 1);
            sig = zeros(common.sig_size, n_img);
            for k=1:n_img
                task_progress(tid, k/n_img);
                sig(:, k) = BOF.sig_from_feat_descr(common.L, common.centers, args(k).feat, args(k).descr, args(k).Ipath, common.zone);
            end  
            
            sig = sig';
            
            task_close(tid);
        end

        %------------------------------------------------------------------
        function sig = sig_from_feat_descr(L, centers, feat, descr, Ipath, zone)
            if size(descr, 1) == 0
                n_bin = sum(L(:,1).*L(:,2));
                sig = zeros(size(centers,1)*n_bin,1);
            else       
                d = dist2(centers, descr);
                m = (d == repmat(min(d), size(d,1), 1));  
                
                if zone > 0 % We draw the grid only on the bounding box
                    [d f] = fileparts(Ipath);
                    f = fullfile(d, sprintf('%s.info', f));
                    bb = load(f, '-ascii');
                    w = bb(4)-bb(2)+1;
                    h = bb(5)-bb(3)+1;
                    X = (feat(:,1)-bb(2))/w;
                    Y = (feat(:,2)-bb(3))/h;
                else            % We draw the grid on the full image
                    info = imfinfo(Ipath);
                    w = info.Width;
                    h = info.Height;                   
                    X = (feat(:,1)-1)/w;
                    Y = (feat(:,2)-1)/h;
                end
                
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
                sig = cat(1,sig{:});
            end
        end  
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = BOF(detector, descriptor, K, norm, L, zone, kmeans_lib, maxiter)
            if nargin < 5 || isempty(L)
                L = [1 1 1];
            end     
            if isscalar(L)
                levels = (0:L)';
                w = 1./2.^(L-levels+1);
                w(1) = 1/2^L;
                L = [2.^levels, 2.^levels, w];                     
            end
            if nargin < 6
                zone = 0;
            end
            if nargin < 7
                kmeans_lib = 'c';
            end
            if nargin < 8
                maxiter = 200;
            end        
            
            obj = obj@SignatureAPI();
            obj.detector = detector;
            obj.descriptor = descriptor;
            obj.K = K;
            obj.kmeans = Kmeans(K, kmeans_lib, maxiter); 
            obj.zone = zone;
            
            n_cells = sum(L(:,1).*L(:,2));
            end_index = cumsum(L(:,1).*L(:,2));
            beg_index = [0; end_index(1:(end-1))];
            obj.L = [L (beg_index*K+1) (end_index*K)];
            obj.L_cv = (L(:,3) == 0);
            obj.sig_size = K*n_cells;
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
                if size(train_sigs,1) == length(Ipaths) && size(train_sigs,2) == obj.sig_size
                    obj.train_sigs = train_sigs';
                else
                    obj.train_sigs = train_sigs;                                
                end
                write_log(sprintf('Loaded.\n'));
            else    
                pg = ProgressBar('Learning training signatures', '');
                progress_value = 0;
 
                feature_progress_frac = 0.15;
                descrip_progress_frac = 0.15;
                k_means_progress_frac = 0.65;
                sigs_progress_frac =    0.05;

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
                obj.train_sigs = obj.compute_signatures(feat, descr, Ipaths, pg, progress_value, sigs_progress_frac);
                               
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

                feature_progress_frac = 0.20;
                descrip_progress_frac = 0.65;
                sigs_progress_frac =    0.15;            

                % Compute feature points
                pg.setCaption('Computing feature points...');
                feat = obj.compute_features(obj.detector, Ipaths, pg, offset, feature_progress_frac*scale);
                progress_value = feature_progress_frac;

                % Compute descriptors
                pg.setCaption('Computing descriptors...');
                descr = obj.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, offset + progress_value*scale, descrip_progress_frac*scale);
                progress_value = progress_value + descrip_progress_frac;

                % Filter features according to the bounding box
                for i=1:length(Ipaths)
                    [f d] = SignatureAPI.filter_by_zone(obj.zone, Ipaths{i}, feat{i}, descr{i});
                    feat{i} = f;
                    descr{i} = d;
                end

                % Compute signature
                pg.setCaption('Computing signatures...');
                sigs = obj.compute_signatures(feat, descr, Ipaths, pg, offset + progress_value*scale, sigs_progress_frac*scale);            

                save(file,'sigs');
                
                if nargin<3
                    pg.close();
                end
            end
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = get_pyramid(obj)
            n_grid = size(obj.L, 1);
            str = cell(1,n_grid);
            for i = 1:n_grid
                if obj.L_cv(i)
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
            detect = obj.detector.toString();
            descrp = obj.descriptor.toString();
            n = obj.norm.toString();    
            klib = obj.kmeans.get_lib();
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('Signature: Bag of features (K = %d, Zone = %d, histogram normalization: %s, K-means library: %s) of:\n$~~~~~~~~$%s of %s\n', obj.K, obj.zone, n, klib, descrp, detect);
            else
                str = sprintf('Signature: Spatial pyramid (K = %d, Zone = %d, L = %s, histogram normalization: %s, K-means library: %s) of\n$~~~~~~~~$%s of %s\n', obj.K, obj.zone, obj.get_pyramid(), n, klib, descrp, detect);
            end
        end
        
        function str = toFileName(obj)
            klib = obj.kmeans.get_lib();
            detect = obj.detector.toFileName();
            descrp = obj.descriptor.toFileName();
            n = obj.norm.toFileName();            
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('BOF[%s-%d-%d-%s-%s-%s]', klib, obj.K, obj.zone, n, descrp, detect);
            else
                str = sprintf('PYR[%s-%d-%d-%s-%s-%s-%s]', klib, obj.K, obj.zone, obj.get_pyramid(), n, descrp, detect);
            end
        end
        
        function str = toName(obj)
            if size(obj.L,1) == 1 && obj.L(1,1)*obj.L(1,2) == 1
                str = sprintf('BOF(%d)', obj.K);
            else
                str = sprintf('PYR(%s)-BOF(%d)', obj.get_pyramid(), obj.K);
            end
        end

        function str = KmeanstoFileName(obj)
            klib = obj.kmeans.get_lib();            
            detect = obj.detector.toFileName();
            descrp = obj.descriptor.toFileName();              
            str = sprintf('Kmeans[%s-%d-%d-%s-%s]', klib, obj.K, obj.zone, descrp, detect);
        end        
    end
end

