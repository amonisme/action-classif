classdef Polynomial < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
        b
        c
    end

    methods        
        %------------------------------------------------------------------
        % Constructor   Kernel type: (a * X.Y + b)^c
        function obj = Polynomial(a,b,c,lib)
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
                lib = 'svmlight';
            end
            
            obj.a = a;
            obj.b = b;
            obj.c = floor(c);
            obj.lib_name = lib;
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for polynomial kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = learn(obj, C, J, labels, sigs, precomputed)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 1 -s %s -r %s -d %d',num2str(C), num2str(J), num2str(obj.a), num2str(obj.b), obj.c));
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Polynomial kernel: (%s * X.Y + %s)^%d',num2str(obj.a), num2str(obj.b), obj.c);
        end
        function str = toFileName(obj)
            str = sprintf('Poly[A(%s)-B(%s)-C(%d)]',num2str(obj.a), num2str(obj.b), obj.c);
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

