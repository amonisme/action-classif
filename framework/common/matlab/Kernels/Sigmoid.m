classdef Sigmoid < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
        b
        param_cv    % remember which parameterter was cross-validated
    end

    methods        
        %------------------------------------------------------------------
        % Constructor   Kernel type: tanh(a * X.Y + b)
        function obj = Sigmoid(a,b,precompute,lib)
            if nargin < 1
                a = [];
            end
            if nargin < 2
                b = [];
            end            
            if nargin < 3
                precompute = 1;
            end
            if nargin < 4
                lib = 'svmlight';
            end
            
            obj = obj@KernelAPI();             
            
            obj.a = a;
            obj.b = b;
            obj.precompute = precompute;
            obj.lib_name = lib;
            
            obj.param_cv = [0 0];
            if isempty(a)
                obj.param_cv(1) = 1;    
            end
            if isempty(b)
                obj.param_cv(2) = 1;    
            end
            
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for sigmoïd kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
            svm = svmlearn(sigs', labels, sprintf('-v 0 -c %s -j %s -t 3 -s %s -r %s',num2str(C), num2str(J), num2str(obj.a), num2str(obj.b)));
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
            [err score] = svmclassify(sigs', zeros(size(sigs,2),1), svm);
        end        
               
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Sigmoid kernel: $tanh(%s * X.Y + %s)$',num2str(obj.a), num2str(obj.b));
        end
        function str = toFileName(obj)
            if obj.param_cv(1)
                a = 'cv';
            else
                a = num2str(obj.a);
            end
            if obj.param_cv(2)
                b = 'cv';
            else
                b = num2str(obj.b);
            end            
            str = sprintf('Sig[%s-%s]',a,b);
        end
        function str = toName(obj)
            str = 'Sig';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function params = set_params(obj, params)
            if ~obj.gram_train_ok || obj.a ~= params(1) || obj.b ~= params(2)
                obj.a = params(1);
                obj.b = params(2);
                obj.gram_train_ok = 0;
            end
            params = params(3:end);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_params(obj, sigs)
            scal = sigs' * sigs;
            
            if obj.precompute
                obj.scalar_prod = scal;
            end  
            
            maxi = max(max(scal));
            avg  = mean(mean(scal));
            
            if isempty(obj.a)
                avg = avg / maxi;
                val_a = (1/maxi) * 2.^(-1:1);
            else
                avg = avg * obj.a;
                val_a = obj.a;
            end
            if isempty(obj.b)
                val_b = (-2:2) - avg;
            else
                val_b = obj.b;
            end            
            params = {(val_a') (val_b')}';
        end
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        function obj = precompute_gram_matrix(obj, sigs1, sigs2)
            if nargin == 1
                obj.gram_matrix = zeros(size(obj.scalar_prod)+1);
                obj.gram_matrix(1,:) = tanh(obj.b);
                obj.gram_matrix(:,1) = tanh(obj.b);
                obj.gram_matrix(2:end, 2:end) = tanh(obj.a * obj.scalar_prod + obj.b);
            else            
                obj.gram_matrix = zeros(size(sigs1,2), size(sigs2,2));
                obj.gram_matrix(1,:) = tanh(obj.b);
                obj.gram_matrix(:,1) = tanh(obj.b);
                obj.gram_matrix(2:end, 2:end) = tanh(obj.a * (sigs1' * sigs2) + obj.b);
            end
        end
    end
end

