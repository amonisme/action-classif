classdef Intersection < KernelAPI
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: sum_i(min(Xi, Yi))
        function obj = Intersection(lib)
            if(nargin < 1)
                lib = 'svmlight';
            end
            
            obj.lib_name = lib;
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for intersection kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1) (precomputed is [] or
        % the file containing the data.)
        function svm = learn(obj, C, J, labels, sigs, precomputed)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 4 -u1',num2str(C), num2str(J)));
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Intersection kernel: sum_i(min(Xi, Yi))');
        end
        function str = toFileName(obj)
            str = 'Intersection';
        end
        function str = toName(obj)
            str = 'Inter';
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
            [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);
        end    
    end  
end

