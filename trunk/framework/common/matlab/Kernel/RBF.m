classdef RBF < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
    end

    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: exp(-1/a*||X-Y||^2)
        function obj = RBF(a,lib)
            if(nargin < 1)
                a = [];
            end
            if(nargin < 2)
                lib = 'svmlight';
            end
            
            obj.a = a;
            obj.lib_name = lib;
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for RBF kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = learn(obj, C, J, labels, sigs, precomputed)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 2 -g %s',num2str(C), num2str(J), num2str(1/obj.a)));
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('RBF kernel: exp(-1/%s*||X-Y||^2)',num2str(obj.a));
        end
        function str = toFileName(obj)
            str = sprintf('RBF[A(%s)]',num2str(obj.a));
        end
        function str = toName(obj)
            str = 'RBF';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function obj = set_params(obj, params)
            obj.a = params(1);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function [params do_cv] = get_testing_params(obj, training_sigs)
            do_cv = false;
            if isempty(obj.a)
                val_a = mean(mean(dist2(training_sigs, training_sigs))) * (1.5.^(-3:3));
                do_cv = true;
            else
                val_a = obj.a;
            end
            params = {val_a'}';
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

