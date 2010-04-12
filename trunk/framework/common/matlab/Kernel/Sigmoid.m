classdef Sigmoid < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
        b
        param_cv    % remember which parameterter was cross-validated
    end

    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if ~isfield(a, 'param_cv')
                obj.param_cv = [1 1];
            end
        end 
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor   Kernel type: tanh(a * X.Y + b)
        function obj = Sigmoid(a,b,lib)
            if(nargin < 1)
                a = [];
            end
            if(nargin < 2)
                b = [];
            end            
            if(nargin < 3)
                lib = 'svmlight';
            end
            
            obj.a = a;
            obj.b = b;
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
        function svm = learn(obj, C, J, labels, sigs, precomputed)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 3 -s %s -r %s',num2str(C), num2str(J), num2str(obj.a), num2str(obj.b)));
        end
               
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Sigmoid kernel: tanh(%s * X.Y + %s)',num2str(obj.a), num2str(obj.b));
        end
        function str = toFileName(obj)
            if obj.param_cv(1)
                a = '?';
            else
                a = num2str(obj.a);
            end
            if obj.param_cv(2)
                b = '?';
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
        function obj = set_params(obj, params)
            obj.a = params(1);
            obj.b = params(2);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function [params do_cv] = get_testing_params(obj, training_sigs)
            scal = [];
            n_sigs = size(training_sigs, 1);
            for i=1:n_sigs
                n = n_sigs - i - 1;
                if n > 0
                    s = training_sigs((i+1):end,:) .* repmat(training_sig(i), n, 1);
                    s = sum(s, 2);
                    scal = cat(1, scal, s);
                end
            end       
            do_cv = false;
            if isempty(obj.a)
                m = 1/max(abs(scal));
                scal = scal * m;
                val_a = m * 2.^(-1:1);
                do_cv = true;
            else
                scal = scal * obj.a;
                val_a = obj.a;
            end
            if isempty(obj.b)
                m = -mean(scal);
                val_b = m + (-2:2);
                do_cv = true;
            else
                val_b = obj.b;
            end            
            params = {(val_a') (val_b')}';
        end
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products for cross-validation
        % If precomputation not supported, returns [], otherwise, returns
        % the path to file where results are saved
        function file = precompute(obj, training_sigs)
            file = [];
        end
    end
    
    methods (Static)
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = classify(svm, sigs, precomputed)
            [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);
        end
    end    
end

