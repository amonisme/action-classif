classdef Polynomial < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
        b
        c
        param_cv    % remember which parameterter was cross-validated
    end

    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if ~isfield(a, 'param_cv')
                obj.param_cv = [1 1 1];
            end
        end 
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor   Kernel type: (a * X.Y + b)^c
        function obj = Polynomial(a,b,c,precompute,lib)
            if(nargin < 1)
                a = [];
            end
            if(nargin < 2)
                b = [];
            end            
            if(nargin < 3)
                c = [];
            end            
            if(nargin < 4)
                precompute = 0;
            end              
            if(nargin < 5)
                lib = 'svmlight';
            end
            
            obj.a = a;
            obj.b = b;
            obj.c = floor(c);
            obj.precompute = precompute;
            obj.lib_name = lib;
            
            obj.param_cv = [0 0 0];
            if isempty(a)
                obj.param_cv(1) = 1;    
            end
            if isempty(b)
                obj.param_cv(2) = 1;    
            end
            if isempty(c)
                obj.param_cv(3) = 1;    
            end            
            
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for polynomial kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 1 -s %s -r %s -d %d',num2str(C), num2str(J), num2str(obj.a), num2str(obj.b), obj.c));
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
            [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);
        end        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Polynomial kernel: (%s * X.Y + %s)^%d',num2str(obj.a), num2str(obj.b), obj.c);
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
            if obj.param_cv(3)
                c = '?';
            else
                c = num2str(obj.c);
            end            
            str = sprintf('Poly[%s-%s-%d]',a,b,c);
        end
        function str = toName(obj)
            str = 'Poly';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function obj = set_params(obj, params)
            obj.a = params(1);
            obj.b = params(2);
            obj.c = params(3);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function [params do_cv] = get_testing_params(obj, training_sigs)
            scal = [];
            n_sigs = size(training_sigs, 1);
            for i=1:n_sigs
                n = n_sigs - i;
                if n > 0
                    s = training_sigs((i+1):end,:) .* repmat(training_sigs(i,:), n, 1);
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
            if isempty(obj.c)
                val_c = 2:4;
                do_cv = true;
            else
                val_c = obj.c;
            end
            params = {(val_a)' (val_b)' (val_c)'};
        end
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        function obj = precompute_gram_matrix(obj, sigs1, sigs2)
            sigs1 = [zeros(1,size(sigs1,2)); sigs1];
            sigs2 = [zeros(1,size(sigs2,2)); sigs2];
            
            obj.gram_matrix = (obj.a * (sigs1 * sigs2') + obj.b) .^ obj.c;
        end
    end
end

