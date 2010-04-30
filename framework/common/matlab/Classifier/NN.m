classdef NN < ClassifierAPI
    
    properties (SetAccess = protected)
        signature   % Signature module        
        class_names
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
            [Ipaths l] = get_labeled_files(root, 'Loading training set...\n');
            
            [class_id names] = names2ids(l);
            obj.labels = class_id;
            obj.class_names = names;
            
            obj.signature.learn(Ipaths);
            cv_res = [];
            cv_dev = [];
        end
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        function [Ipaths classes correct_label assigned_label score] = classify(obj, Ipaths, correct_label)
            classes = obj.class_names;
            if nargin < 3
                [Ipaths l] = get_labeled_files(Ipaths, 'Loading testing set...\n');
                correct_label = names2ids(l, classes);
            end

            pg = ProgressBar('Classifying', 'Computing signatures...');
            sigs = obj.signature.get_signatures(Ipaths, pg, 0, 0.95);
            
            n_classes = size(classes, 1);
            n_img = size(Ipaths, 1);
            n_train = size(obj.labels, 1);

            dist = zeros(n_train, 1);
            assigned_label = zeros(n_img,1);
            score = zeros(n_img,n_classes);

            
            pg.setCaption('Assigning labels...');
            for i=1:n_img
                pg.progress(0.95+0.05*i/n_img);                
                for j=1:n_train
                    dist(j) = chi2(sigs(i, :), obj.signature.train_sigs(j, :)); 
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
                    score(i,j) = dist_neg / (dist_pos + dist_neg);
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
        function obj = save_to_temp(obj)
            obj.signature.save_to_temp();
        end
    end
end

