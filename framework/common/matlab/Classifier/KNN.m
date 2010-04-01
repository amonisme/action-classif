classdef KNN < NN
   
    properties (SetAccess = protected, GetAccess = protected)
        K
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = KNN(K, signature)
            obj = obj@NN(signature);
            obj.K = K;
        end
        
        %------------------------------------------------------------------
        % Learns from the training directory 'root'
        function cross_validation = learn(obj, root)
            [Ipaths l] = get_labeled_files(root);
            
            [class_id names] = names2ids(l);
            obj.labels = class_id;
            obj.class_names = names;
            
            obj.signature.learn(Ipaths);
            cross_validation = [];
        end
        
        %------------------------------------------------------------------
        % Classify the testing directory 'root'
        function [Ipaths classes correct_label assigned_label score] = classify(obj, Ipaths, correct_label)
            classes = obj.class_names;
            n_classes = size(classes, 1);
            if nargin < 3
                [Ipaths l] = get_labeled_files(Ipaths, 'Loading testing set...\n');
                correct_label = names2ids(l, classes);
            end
            
            pg = ProgressBar('Classifying', 'Computing signatures...');
            sigs = obj.signature.get_signatures(Ipaths, pg, 0, 0.95);

            n_img = size(Ipaths, 1);
            n_train = size(obj.labels, 1);

            dist = zeros(n_train, 1);
            assigned_label = zeros(n_img,1);
            score = zeros(n_img, n_classes);
            n_sample = min(obj.K, n_train);
            
            pg.setCaption('Assigning labels...');
            for i=1:n_img
                pg.progress(0.95 + 0.05*i/n_img);   
                for j=1:n_train
                    dist(j) = chi2(sigs(i, :), obj.signature.train_sigs(j, :)); 
                end
                [dist I] = sort(dist);
                l = obj.labels(I);
                
                % Scores
                d = zeros(n_classes, 1);
                for j = 1:n_classes
                    d(j) = mean(dist(find(l == j, n_sample)));
                end
                for j = 1:n_classes
                    dist_pos = d(j);
                    dist_neg = min(d([1:(j-1) (j+1):n_classes]));
                    score(i,j) = dist_neg / (dist_pos + dist_neg);
                end            
                
                % Label
                vote = zeros(n_classes, 2);                
                for k=1:n_sample
                    vote(l(k),:) = vote(l(k),:) + [1 score(i,l(k))];
                end
                [vote I] = sortrows(vote, [-1 -2]);
                assigned_label(i) = I(1);
            end
            pg.close();
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = [sprintf('Classifier: K-Nearest Neighbours (K = %d)\n', obj.K) obj.signature.toString()];
        end
        function str = toFileName(obj)
            str = sprintf('KNN[K(%d)]_%s', obj.K, obj.signature.toFileName());
        end
        function str = toName(obj)
            str = sprintf('KNN(%d)', obj.K);
        end
    end
    
end

