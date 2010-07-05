classdef GrowingTree < ClassifierAPI

    properties
        detector
        descriptor
        
        n_basis_features
        kmeans_basis         
        basis_feat
        
        n_unit_features_sample
        n_unit_features
        kmeans_unit 
        
        models
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = GrowingTree()
            obj.detector = MS_Dense(10,1.4,5);
            %obj.detector = Harris;
            obj.descriptor = SIFT(L2Trunc);
            obj.n_basis_features = 1024;
            obj.kmeans_basis = Kmeans(obj.n_basis_features, 'c', 200);
            obj.n_unit_features_sample = 1000;   
            obj.n_unit_features = 100;
        end
        
        %------------------------------------------------------------------
        % Learn the training set signatures
        function [cv_prec cv_dev_prec cv_acc cv_dev_acc] = learn(obj, root)          
            global TEMP_DIR HASH_PATH USE_PARALLEL;
    
            [Ipaths ids map c_names subc_names] = get_labeled_files(root, 'Loading training set...\n'); 
            obj.store_names(c_names, subc_names, map);
            n_classes = max(ids);
            
            pg = ProgressBar('Let''s go!', '');
            
            % Compute bounding boxes
            n_img = length(ids);
            bounding_boxes = zeros(n_img, 4);
            for i=1:n_img
                bb = get_bb_info(Ipaths{i});
                bounding_boxes(i,:) = bb(2:5);
            end                

            % Compute feature points
            pg.setCaption('Computing feature points...');
            feat =  SignatureAPI.compute_features(obj.detector, Ipaths, pg, 0, 1);
            
            % Compute descriptors
            pg.setCaption('Computing descriptors...');
            descr = SignatureAPI.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, 0, 1);

            % Compute basis
            obj.kmeans_basis.prepare_kmeans(descr);
            obj.basis_feat = obj.kmeans_basis.do_kmeans(fullfile(TEMP_DIR, sprintf('%s_myalgo-basis-%d-%s-%s.mat', HASH_PATH, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName())));
    
            % Assign descriptors to basis
            file = fullfile(TEMP_DIR, sprintf('%s_myalgo-basis-assign-%d-%s-%s.mat', HASH_PATH, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
            if exist(file, 'file') == 2
                load(file);
                fprintf('Assignement loaded from %s.\n', file);
            else
                pg.setCaption('Assign descriptors to basis...');
                assign = cell(n_img, 1);      
                for i = 1:n_img
                    pg.progress(i/n_img);
                    d = dist2(obj.basis_feat, descr{i});
                    m = (d == repmat(min(d), size(d,1), 1));
                    n_descr = size(descr{i}, 1);
                    assign{i} = zeros(n_descr, 1);
                    for j=1:n_descr
                        a = find(m(:,j), 1);
                        assign{i}(j) = a;
                    end
                end  
                save(file, 'assign');
            end
            
            % Compute basis scores                                  
            pg.setCaption('Scoring basis features...');
            file = fullfile(TEMP_DIR, sprintf('%s_myalgo-basis-feat-scores-%d-%s-%s.mat', HASH_PATH, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
            if exist(file, 'file') == 2
                load(file);
                fprintf('Scores loaded from %s.\n', file);
            else
                if USE_PARALLEL
                    common = struct('n_classes', n_classes, 'ids', ids, 'descr', [], 'assign', []);                    
                    common.descr = descr;
                    common.assign = assign;
                    basis_scores = run_in_parallel('compute_parallel_basis_feat_score', common, obj.basis_feat, 0, 0);
                else
                    basis_scores = zeros(obj.n_basis_features, n_classes,2);                    
                    support = zeros(obj.n_basis_features, n_classes);
    
                    for i = 1:n_classes
                        I = find(ids == i);
                        s = zeros(1, obj.n_basis_features);
                        for j = 1:length(I)
                            for k = 1:obj.n_basis_features
                                J = (assign{I(j)} == k);
                                if ~isempty(find(J,1))
                                    s(k) = s(k) + max(descr{I(j)}(J,:) * obj.basis_feat(k,:)');
                                end
                            end
                        end
                        support(:, i) = s' / length(I);
                    end
                    
                    for i = 1:n_classes
                        basis_scores(:,i,1) = support(:, i);
                        basis_scores(:,i,2) = support(:, i) ./ max(support(:,(1:n_classes)~=i), [], 2);
                    end
                end        
                save(file, 'basis_scores');
            end                        
                                            
            % Learn models
            obj.models = cell(n_classes, 1);            
            for i = 1:n_classes
                obj.models{i} = obj.learn_model(bounding_boxes, feat, descr, assign, ids, basis_scores, i, pg);
            end
            
            cv_prec = [];
            cv_dev_prec = [];
            cv_acc = [];
            cv_dev_acc = [];

            pg.close();
        end
        
        %------------------------------------------------------------------
        % Learn a model per class
        function model = learn_model(obj, bounding_boxes, feat, descr, assign, ids, basis_scores, class, pg)
            global TEMP_DIR HASH_PATH USE_PARALLEL;
            
            modelfile = fullfile(TEMP_DIR, sprintf('%s_myalgo-model%d-%d-%s-%s.mat', HASH_PATH, class, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
            if exist(modelfile, 'file') == 2
                load(modelfile);
                fprintf('Model loaded from %s.\n', modelfile);
            else
                n_classes = max(ids);
                score = basis_scores(:,class,1) .* basis_scores(:,class,2);
                [score I] = sort(score, 'descend');

                n_centers = 10;
                n_basis_selected = ceil(sqrt(2 * obj.n_unit_features_sample / n_centers));
                new_n_unit_features_sample = n_basis_selected*(n_basis_selected+1)/2*n_centers;

                km = Kmeans(n_centers,'c',200);

                pg.setCaption(sprintf('Computing model %d on %d.', class, n_classes));
                file = fullfile(TEMP_DIR, sprintf('%s_myalgo-premodel%d-%d-%s-%s.mat', HASH_PATH, class, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
                if exist(file, 'file') == 2
                    load(file);
                    fprintf('Premodel basis loaded from %s.\n', file);
                else
                    basis = obj.basis_feat(I(1:n_basis_selected),:);
                    model = struct('c1', {1:n_basis_selected}, 'c2_p', []);
                    for i=1:n_basis_selected
                        pg.progress(i/n_centers);
                        model(i).c1 = I(i);
                        model(i).c2_p = struct('c2', {i:n_basis_selected}, 'p', [], 'invsigma', []);
                        for j=i:n_basis_selected                                               
                            V = collect_basis_feat_vector(bounding_boxes, feat, ids, assign, I(i), I(j));
                            V = V(V(:,3)==class, :);
                            n_vect = size(V,1);
                            km.prepare_kmeans_fused(V(:,1:2));
                            centers = km.do_kmeans();

                            d = dist2(centers, V(:,1:2));
                            m = (d == repmat(min(d), n_centers, 1));
                            idc = zeros(n_vect,1);
                            for k=1:n_vect
                                idc(k) = find(m(:,k),1);
                            end

                            model(i).c2_p(j-i+1).c2 = I(j);
                            model(i).c2_p(j-i+1).p = zeros(n_centers, 2);
                            model(i).c2_p(j-i+1).invsigma = cell(n_centers, 1);
                            deleteI = zeros(1, n_centers);
                            for k=1:n_centers                            
                                J = (idc == k);
                                n_points = length(find(J));
                                if n_points >= 3
                                    diff = V(J,1:2) - repmat(centers(k,:), n_points, 1);
                                    sigma = (diff' * diff) / n_points;

                                    if rcond(sigma) > 10^(-10)                                    
                                        model(i).c2_p(j-i+1).p(k,:) = centers(k,:);  
                                        model(i).c2_p(j-i+1).invsigma{k} = sigma^(-1);
                                    else
                                        deleteI(k) = 1;
                                        new_n_unit_features_sample = new_n_unit_features_sample-1;
                                    end                                
                                else
                                    deleteI(k) = 1;
                                    new_n_unit_features_sample = new_n_unit_features_sample-1;
                                end
                            end
                            deleteI = logical(deleteI);
                            model(i).c2_p(j-i+1).p(deleteI,:) = [];                        
                            model(i).c2_p(j-i+1).invsigma(deleteI) = [];
                        end
                    end
                    save(file, 'model', 'basis');
                end

                
                file = fullfile(TEMP_DIR, sprintf('%s_myalgo-premodel%d-basis-scores-%d-%s-%s.mat', HASH_PATH, class, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
                if exist(file, 'file') == 2
                    load(file);
                    fprintf('Premodel loaded from %s.\n', file);
                else
                    basis_scores = zeros(new_n_unit_features_sample, 2);                    
                    support = zeros(new_n_unit_features_sample, n_classes);

                    for i = 1:n_classes
                        subfile = fullfile(TEMP_DIR, sprintf('%s_myalgo-premodel%d-class%d-basis-scores-%d-%s-%s.mat', HASH_PATH, class, i, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
                        if exist(subfile, 'file') == 2
                            load(subfile);
                            fprintf('Sub-premodel loaded from %s.\n', subfile);
                        else
                            I = find(ids == i);
                            if USE_PARALLEL
                                common = struct('feat', [], 'descr', [], 'basis', basis, 'model', model, 'bounding_boxes', bounding_boxes, 'n_basis_selected', n_basis_selected, 'n_unit_features_sample', new_n_unit_features_sample);                    
                                common.feat = feat(I);
                                common.descr = descr(I);
                                s = run_in_parallel('compute_parallel_unit_feat_score', common, (1:length(I))', [], 1200);
                                s = sum(s,1);
                            else
                                s = zeros(1, new_n_unit_features_sample);                    
                                for j = 1:length(I)
                                    width = bounding_boxes(j,3) - bounding_boxes(j,1) + 1;
                                    height = bounding_boxes(j,4) - bounding_boxes(j,2) + 1;
                                    scale = max(width, height);
                                    sfeat = feat{I(j)}(:,1:2) / scale;
                                    sdescr = descr{I(j)} * basis';

                                    n_feat = size(sfeat,1);
                                    k = 1;
                                    for u = 1:n_basis_selected
                                        sc1 = sdescr(:,model(u).c1);
                                        for v = u:n_basis_selected  
                                            n_descr = length(descr{I(j)});
                                            sc2 = sdescr(:,model(u).c2_p(v-u+1).c2);
                                            %sc = sc1 * sc2';                                        
                                            sc = repmat(sc1, 1, n_descr) + repmat(sc2', n_descr, 1);
                                            n_centers = size(model(u).c2_p(v-u+1).p, 1);
                                            for w = 1:n_centers
                                                p = model(u).c2_p(v-u+1).p(w,:);
                                                invsigma = model(u).c2_p(v-u+1).invsigma{w};
                                                %const_gauss = sqrt(det(invsigma))/(2*pi);
                                                best_score = 0;
                                                for x=1:n_feat
                                                    if x == 1
                                                        if size(p,2)>2
                                                            model(u).c2_p(v-u+1).p
                                                        end
                                                        vects = sfeat - repmat(sfeat(x,:) + p, n_feat, 1);
                                                        VectsTSigma = vects * invsigma;
                                                        VectsTSigmaVects2 = sum(VectsTSigma .* vects, 2) / 2;
                                                        xTO1 = [0 0];
                                                    else
                                                        xTO1 = sfeat(1,:) - sfeat(x,:);
                                                    end
                                                    d = VectsTSigmaVects2 + VectsTSigma * xTO1' + (xTO1 * invsigma * xTO1') / 2;
                                                    J = (d<10);
                                                    if ~isempty(find(J,1))
                                                        smax = max(sc(x,J)' .* exp(-d(J)));
                                                        %best_score = max(best_score, const_gauss * smax); 
                                                        best_score = max(best_score, smax); 
                                                    end
                                                end
                                                s(k) = s(k) + best_score;
                                                k = k + 1;
                                            end
                                        end
                                    end                    
                                end
                            end
                            s = s' / length(I);
                            support(:, i) = s;
                            save(subfile, 's');
                        end                    
                    end

                    for i = 1:n_classes                
                        basis_scores(:,i,1) = support(:, i);
                        basis_scores(:,i,2) = support(:, i) ./ max(support(:,(1:n_classes)~=i), [], 2);
                    end

                    bar(sort(basis_scores(:,class,1) .* basis_scores(:,class,2)));
                    save(file, 'basis_scores');
                end
                
                
                
                file = fullfile(TEMP_DIR, sprintf('%s_myalgo-model%d-unit-feat-%d-%s-%s.mat', HASH_PATH, class, obj.n_basis_features, obj.descriptor.toFileName(), obj.detector.toFileName()));
                if exist(file, 'file') == 2
                    load(file);
                    fprintf('Model unit-feat loaded from %s.\n', file);
                else
                    [s index] = sort(basis_scores(:,class,2), 'descend');

                    n_unit = min(obj.n_unit_features, length(index));               
                    unit_feat = struct('c1', {1:n_unit}', 'c2', [], 'p', [], 'invsigma', []);

                    s_index = sort(index(1:n_unit));

                    k = 1;
                    n = 0;
                    for u=1:n_basis_selected
                        for v=u:n_basis_selected
                            next_n = n + size(model(u).c2_p(v-u+1).p,1);
                            while 1
                                if s_index(k) > n && s_index(k) <= next_n
                                    unit_feat(k).c1 = model(u).c1;
                                    unit_feat(k).c2 = model(u).c2_p(v-u+1).c2;
                                    unit_feat(k).p  = model(u).c2_p(v-u+1).p(s_index(k)-n,:);
                                    unit_feat(k).invsigma = model(u).c2_p(v-u+1).invsigma{s_index(k)-n};
                                    k = k+1;
                                    if k>n_unit
                                        break;
                                    end
                                else
                                    n = next_n;
                                    break;
                                end
                            end
                            if k>n_unit
                                break;
                            end
                        end
                        if k>n_unit
                            break;
                        end                        
                    end
                    save(file, 'unit_feat');
                end
                
                n_img = length(feat);
                n_unit_feat = length(unit_feat);                
                sigs = zeros(n_unit_feat, n_img);
                
                % Computes signatures
                pg.setCaption('Computing signatures...');
                for i = 1:n_img
                    pg.progress(i/n_img);
                    width = bounding_boxes(i,3) - bounding_boxes(i,1) + 1;
                    height = bounding_boxes(i,4) - bounding_boxes(i,2) + 1;
                    scale = max(width, height);                 
                    sfeat = feat{i} / scale;
                    sdescr = descr{i} * basis';                                        
                    
                    for j = 1:n_unit_feat
                        n_feat = size(sfeat, 1);
                        sc = repmat(sdescr(:,unit_feat(j).c1), 1, n_feat) + repmat(sdescr(:,unit_feat(j).c2)', n_feat, 1);
                        best_score = 0;    
                        [maxi I] = sort(max(sc,[],2), 'descend');
                        for x = 1:n_feat
                            if maxi(x) < best_score
                                break;
                            end
                            real_x = I(x);
                            
                            if x == 1
                                vects = sfeat(:,1:2) - repmat(sfeat(1,1:2) + unit_feat(j).p, n_feat, 1);
                                VectsTSigma = vects * unit_feat(j).invsigma;
                                VectsTSigmaVects2 = sum(VectsTSigma .* vects, 2) / 2;
                                xTO1 = [0 0];
                            else
                                xTO1 = sfeat(1,1:2) - sfeat(real_x,1:2);
                            end
                            d = VectsTSigmaVects2 + VectsTSigma * xTO1' + (xTO1 * unit_feat(j).invsigma * xTO1') / 2;

                            J = (d<10);        
                            if ~isempty(find(J,1))                
                                smax = max(sc(real_x,J)' .* exp(-d(J)));        
                                if best_score < smax
                                    best_score = smax;
                                end
                            end
                        end                         
                        
                        sigs(j,i) = best_score;
                    end
                end
            
                model = struct('basis', basis, 'unit_feat', unit_feat, 'kernel', Linear(0), 'svm', []);
                C = 1/mean(sum(sigs.*sigs,1));
                model.svm = model.kernel.learn(C, 1, (ids==class)*2-1, sigs);
                save(modelfile, 'model');
            end                                   
        end
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        function [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = classify(obj, Ipaths) 
            global USE_PARALLEL;
            
            classes = obj.classes_names;
            subclasses = obj.subclasses_names;
            map_sub2sup = obj.map_sub2sup;     
            
            [Ipaths ids] = get_labeled_files(Ipaths, 'Loading testing set...\n');            
            correct_label = ids;
            
            n_classes = length(classes);
            n_img = length(Ipaths);
            
            pg = ProgressBar('Classifying', '');
            
            % Compute bounding boxes
            bounding_boxes = zeros(n_img, 4);
            for i=1:n_img
                bb = get_bb_info(Ipaths{i});
                bounding_boxes(i,:) = bb(2:5);
            end                

            % Compute feature points
            pg.setCaption('Computing feature points...');
            feat =  SignatureAPI.compute_features(obj.detector, Ipaths, pg, 0, 1);
            
            % Compute descriptors
            pg.setCaption('Computing descriptors...');
            descr = SignatureAPI.compute_descriptors(obj.detector, obj.descriptor, Ipaths, feat, pg, 0, 1);
            norm = L2(1);            
            for i=1:n_img
                descr{i} = norm.normalize(descr{i}')';
            end
            
            % Computing scores
            scores = zeros(n_img,n_classes);                        
            if USE_PARALLEL
                pg.setCaption('Computing scores...');
                common = struct('feat', [], 'descr', [], 'bounding_boxes', bounding_boxes);
                common.feat = feat;
                common.descr = descr;
                scores = run_in_parallel('compute_parallel_model_score', common, obj.models, [], 2000)';
            else                
                for k = 1:n_classes
                    pg.setCaption(sprintf('Computing scores... (model %d)',k));
                    n_unit_feat = length(obj.models{k}.unit_feat);                
                    sigs = zeros(n_unit_feat, n_img);

                    % Computes signatures
                    for i = 1:n_img
                        pg.progress((k-1+i/n_img)/n_classes);
                        for j = 1:n_unit_feat                    
                            sigs(j,i) = fit_unit_feat(feat{i}, descr{i}, bounding_boxes(i,:), obj.models{k}.unit_feat(j));
                        end
                    end

                    scores(:,k) = obj.models{k}.kernel.classify(obj.models{k}.svm, sigs);
                end
            end
            
            % Assigning labels
            pg.setCaption('Assigning labels...');
            assigned_label = zeros(n_img,1);
            for i=1:n_img
                [m, j] = max(scores(i,:));
                assigned_label(i) = j;
            end
        end              
        
        %------------------------------------------------------------------
        function str = toString(obj)            
            str = 'Signature: Growing Tree';            
        end
        
        function str = toFileName(obj)
            detect = obj.detector.toFileName();
            descrp = obj.descriptor.toFileName();       
            str = sprintf('GT[%d-%d-%s-%s]', obj.n_basis_features, obj.n_unit_features, descrp, detect);
        end
        
        function str = toName(obj)
            str = sprintf('GT(%d-%d)', obj.n_basis_features, obj.n_unit_features);
        end           
    end   
    
    methods (Static)
        %------------------------------------------------------------------
        % Computes signatures
        function sig = get_signatures(feat, descr, bb, model)
            width = bb(3) - bb(1) + 1;
            height = bb(4) - bb(2) + 1;
            scale = max(width, height);                 
            sfeat = feat / scale;
            sdescr = descr * model.basis';
            
            n_unit_feat = length(model.unit_feat);   
            sig = zeros(1, n_unit_feat);

            for j = 1:n_unit_feat
                n_feat = size(sfeat, 1);
                sc = repmat(sdescr(:,model.unit_feat(j).c1), 1, n_feat) + repmat(sdescr(:,model.unit_feat(j).c2)', n_feat, 1);
                best_score = 0;    
                [maxi I] = sort(max(sc,[],2), 'descend');
                for x = 1:n_feat
                    if maxi(x) < best_score
                        break;
                    end
                    real_x = I(x);

                    if x == 1
                        vects = sfeat(:,1:2) - repmat(sfeat(1,1:2) + model.unit_feat(j).p, n_feat, 1);
                        VectsTSigma = vects * model.unit_feat(j).invsigma;
                        VectsTSigmaVects2 = sum(VectsTSigma .* vects, 2) / 2;
                        xTO1 = [0 0];
                    else
                        xTO1 = sfeat(1,1:2) - sfeat(real_x,1:2);
                    end
                    d = VectsTSigmaVects2 + VectsTSigma * xTO1' + (xTO1 * model.unit_feat(j).invsigma * xTO1') / 2;

                    J = (d<10);        
                    if ~isempty(find(J,1))                
                        smax = max(sc(real_x,J)' .* exp(-d(J)));        
                        if best_score < smax
                            best_score = smax;
                        end
                    end
                end                         

                sig(j) = best_score;
            end
        end
    end
end