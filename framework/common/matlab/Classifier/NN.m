classdef NN < ClassifierAPI
    
    properties (SetAccess = protected)
        signature   % Signature module        
        labels      % Id of the class for each training image
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = NN(signature)
            obj = obj@ClassifierAPI(signature);
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function [cv_res cv_dev] = learn(obj, root)
            [Ipaths ids map c_names subc_names] = get_labeled_files(root, 'Loading training set...\n');            
            obj.store_names(c_names, subc_names, map);           
            obj.labels = ids;
            
            obj.signature.learn(Ipaths);
            cv_res = [];
            cv_dev = [];
        end
        
        %------------------------------------------------------------------
        % Classify 
        function [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = classify(obj, Ipaths, correct_label)
            classes = obj.class_names;
            subclasses = obj.subclasses_names;
            map_sub2sup = obj.map_sub2sup;
            if nargin < 3
                [Ipaths ids] = get_labeled_files(Ipaths, 'Loading testing set...\n');            
                correct_label = ids;
            end

            pg = ProgressBar('Classifying', 'Computing signatures...');
            sigs = obj.signature.get_signatures(Ipaths, pg, 0, 0.95);
            
            n_classes = size(classes, 1);
            n_img = size(Ipaths, 1);
            n_train = size(obj.labels, 1);

            dist = zeros(n_train, 1);
            assigned_label = zeros(n_img,1);
            scores = zeros(n_img,n_classes);
            
            pg.setCaption('Assigning labels...');
            for i=1:n_img
                pg.progress(0.95+0.05*i/n_img);                
                for j=1:n_train
                    dist(j) = chi2(sigs(:, i), obj.signature.train_sigs(:, j)); 
                end
                [dist I] = sort(dist);
                l = obj.labels(I);
                
                % Scores
                d = zeros(n_classes, 1);
                for j = 1:n_classes
                    d(j) = dist(find(l == j, 1));
                end
                for j = 1:n_classes
                    dist_pos = d(j);
                    dist_neg = min(d([1:(j-1) (j+1):n_classes]));
                    scores(i,j) = dist_neg / (dist_pos + dist_neg);
                end     
                
                % Label
                assigned_label(i) = l(1);
            end   
            pg.close();
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = ['Classifier: Nearest Neighbours\n' obj.signature.toString()];
        end
        function str = toFileName(obj)
            str = sprintf('NN-%s', obj.signature.toFileName());
        end
        function str = toName(obj)
            str = 'NN';
        end
    end
end

