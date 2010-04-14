classdef Linear < KernelAPI
    
    methods        
        %------------------------------------------------------------------
        % Constructor
        function obj = Linear(lib)
            if(nargin < 1)
                lib = 'svmlight';
            end
            
            obj.lib_name = lib;
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for linear kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = learn(obj, C, J, labels, sigs, precomputed)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 0',num2str(C), num2str(J)));
            svm.b = -svm.b;
            svm.W = sum(repmat(svm.a, 1, size(sigs, 2)) .* sigs)';
        end
               
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = 'Linear kernel';
        end
        function str = toFileName(obj)
            str = 'Lin';
        end
        function str = toName(obj)
            str = 'Lin';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function obj = set_params(obj, params)
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function [params do_cv] = get_testing_params(obj, training_sigs)
            params = {};
            do_cv = false;
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
            score = sigs*svm.W+svm.b;
        end
    end  
end

