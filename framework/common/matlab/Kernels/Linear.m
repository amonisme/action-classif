classdef Linear < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        scalar_prod
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor
        function obj = Linear(precompute,lib)
            if nargin < 1
                precompute = 0;
            end              
            if nargin < 2
                lib = 'svmlight';
            end
            
            obj = obj@KernelAPI();    
            
            obj.precompute = precompute;
            obj.lib_name = lib;
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for linear kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 0',num2str(C), num2str(J)));
            svm.b = -svm.b;
            svm.W = sum(repmat(svm.a, 1, size(sigs, 2)) .* sigs)';
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
            score = sigs*svm.W+svm.b;
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
        function params = set_params(obj, params)
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_params(obj, sigs)
            params = {};
            if obj.precompute
                obj.precompute_gram_matrix(sigs, sigs);
                sigs = [zeros(1,size(sigs,2)); sigs];                
                obj.sigs = sigs;
            end
        end      
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        function obj = precompute_gram_matrix(obj, sigs1, sigs2)
            if nargin > 1
                sigs1 = [zeros(1,size(sigs1,2)); sigs1];
                sigs2 = [zeros(1,size(sigs2,2)); sigs2];

                obj.gram_matrix = sigs1 * sigs2';
            end
        end
    end
end

