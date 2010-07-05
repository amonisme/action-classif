classdef LogisticSVM < SVM
    
    properties
        weights     % the weight of the scores
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = LogisticSVM(signatures, kernels, strat, C, J, K)
            if(nargin < 3)
                strat = 'OneVsAll';
            end
            if(nargin < 4)
                C = [];
            end
            if(nargin < 5)
            	J = 1;
            end
            if(nargin < 6)
            	K = 5;
            end
            
            obj = obj@SVM(signatures, kernels, strat, C, J, K);
        end
        
        %------------------------------------------------------------------
        function obj = learn_svm(obj, train_sigs, labels, do_pg)
            if nargin < 4
                do_pg = 1;
            end
            obj.learn_svm@SVM(train_sigs, labels, do_pg);
            
            n_classes = length(obj.classes_names);
            obj.weights = [eye(n_classes); zeros(1,n_classes)];
            [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = obj.classify(train_sigs, labels, do_pg);           
            obj.weights = normalize_scores(scores, labels);            
        end
        
        %------------------------------------------------------------------
        function [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = classify(obj, Ipaths, correct_label, do_pg)
            if nargin < 3
                [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = obj.classify@SVM(Ipaths);
            else
                if nargin < 4
                    do_pg = 1;
                end
                [Ipaths classes subclasses map_sub2sup correct_label assigned_label scores] = obj.classify@SVM(Ipaths, correct_label, do_pg);
            end
            
            scores = (1 + exp(-[scores ones(size(scores,1), 1)] * obj.weights)) .^ -1;           
            for i=1:size(scores, 1)
                [m, j] = max(scores(i,:));
                assigned_label(i) = j;
            end
        end
        
        %------------------------------------------------------------------
        function str = toString(obj)
            if obj.OneVsOne
                strat = 'one VS one';
            else
                strat = 'one VS all';
            end
            if obj.param_cv(1)
                c = '?';
            else
                c = num2str(obj.C);
            end
          
            if isa(obj.kernel, 'MultiKernel')
                str_ker = obj.kernel.toString();
            else
                n_sigs = length(obj.signature); 
                str = cell(1, n_sigs);
                for i=1:n_sigs
                    str{i} = obj.signature{i}.toString();
                    str{i} = sprintf('$~~~~$%s\n', str{i});
                end
                str = cat(2,str{:});            
                str_ker = sprintf('%s:\n%s', obj.kernel.toString(), str);
            end
            
            str = sprintf('Classifier: Logistic SVM %s (C = %s, J = %s) %d-fold cross-validation\n%s',strat, c, num2str(obj.J), obj.K, str_ker);
        end
        
        %------------------------------------------------------------------
        function str = toFileName(obj)
            str = ['Log' obj.toFileName@SVM()];
        end
        
        %------------------------------------------------------------------
        function str = toName(obj)
            str = ['Log' obj.toName@SVM()];
        end            
    end 
end

