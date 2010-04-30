classdef RBF < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
        param_cv    % remember which parameterter was cross-validated
        dist        % remember distances for cross validation
    end

    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
%             if ~isfield(a, 'param_cv')
%                 obj.param_cv = [1];
%             end
        end 
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: exp(-1/a*||X-Y||^2)
        function obj = RBF(a,precompute,lib)
            if nargin < 1
                a = [];
            end
            if nargin < 2
                precompute = 0;
            end            
            if nargin < 3
                lib = 'svmlight';
            end
            
            obj = obj@KernelAPI();             
            
            obj.a = a;
            obj.precompute = precompute;
            obj.lib_name = lib;
            
            obj.param_cv = [0];
            if isempty(a)
                obj.param_cv(1) = 1;    
            end
            
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for RBF kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 2 -g %s',num2str(C), num2str(J), num2str(1/obj.a)));
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
            [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);           
        end        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('RBF kernel: $exp(-1/%s*||X-Y||^2$)',num2str(obj.a));
        end
        function str = toFileName(obj)
            if obj.param_cv(1)
                a = '?';
            else
                a = num2str(obj.a);
            end            
            str = sprintf('RBF[%s]',a);
        end
        function str = toName(obj)
            str = 'RBF';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function params = set_params(obj, params)
            if ~obj.gram_train_ok || obj.a ~= params(1)
                obj.a = params(1);
                obj.gram_train_ok = 0;
            end
            params = params(2:end);
        end
        
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_params(obj, sigs)
            sigs = [zeros(1,size(sigs,2)); sigs];           
            n = size(sigs,1);            
            d = repmat(sum(sigs.^2,2),1,n) - 2*(sigs*sigs') + repmat(sum(sigs.^2,2)',n,1);
            
            if obj.precompute
                obj.sigs = sigs;
                obj.dist = d;
            end
            
            if isempty(obj.a)
                val_a = mean(mean(d)) * (1.5.^(-3:3));
            elseif obj.a == -1                                
                val_a = mean(mean(d));
            else
                val_a = obj.a;
            end
            params = {val_a'}';
        end       
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        function obj = precompute_gram_matrix(obj, sigs1, sigs2)
            if nargin == 1
                obj.gram_matrix = exp( - obj.dist / obj.a);
            else
                sigs1 = [zeros(1,size(sigs1,2)); sigs1];
                sigs2 = [zeros(1,size(sigs2,2)); sigs2];

                n1 = size(sigs1,1);
                n2 = size(sigs2,1);

                D2 = repmat(sum(sigs1.^2,2),1,n2) - 2*sigs1*sigs2' + repmat(sum((sigs2).^2,2)',n1,1);
                obj.gram_matrix = exp( - D2 / obj.a);
            end
        end   
    end
end

