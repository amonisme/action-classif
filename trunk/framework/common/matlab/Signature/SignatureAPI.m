classdef SignatureAPI < handle
    % Signature Interface 
    properties
        channels            % input channels
        channel_sig_size    % Dimensionnality of the signature for one channel
        total_sig_size      % Dimensionnality of the total signature
        train_sigs          % Training signatures
        norm                % Norm used to normalize signatures
    end
    
    methods (Abstract)
        % Learn the training set signatures
        learn(obj, Ipaths)
        
        % Return the signature of the Images
        sigs = get_signatures(obj, Ipaths)        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
    methods (Static = true)      
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
                n_img = size(Ipaths,1);
                
                if ~detector.is_rotation_invariant()
                    for k=1:n_img
                        f = feat{k};
                        f(:,4:5) = 0;
                        feat{k} = f;
                    end
                end
                
                if USE_PARALLEL
                    descr = run_in_parallel('Descriptor_run_parallel', descriptor, horzcat(Ipaths,feat), 0, 0, pg, offset, scale);
                else
                    descr = cell(n_img, 1);
                    for k=1:n_img
                        pg.progress(offset+scale*k/n_img);
                        descr{k} = descriptor.get_descriptors(Ipaths{k}, feat{k});
                    end
                end      
                save(file, 'descr');
            end
        end
    end    
end

