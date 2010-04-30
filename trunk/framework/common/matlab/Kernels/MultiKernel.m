classdef MultiKernel < KernelAPI
    properties (SetAccess = protected)
        kernels
        signatures
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: K1(X,Y) + K2(X,Y)
        function obj = MultiKernel(signatures, kernels)
            obj.signatures = signatures;
            obj.kernels = kernels;
            for i=1:length(kernels)
                obj.kernels{i}.dont_save_gram();
            end
            obj.precompute = 1;
            obj.lib = 0;
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1) (precomputed is [] or
        % the file containing the data.)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
        end        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            n_ker = length(obj.kernels); 
            str = cell(1, n_ker);
            for i=1:n_ker
                str{i} = sprintf('%s\n$~~~~$%s\n', obj.kernels{i}.toString(), obj.signatures{i}.toString());
            end
            str = sprintf('Multi-kernels:\n%s', cat(2,str{:}));
        end
        function str = toFileName(obj)
            n_ker = length(obj.kernels); 
            str = cell(1, n_ker);
            for i=1:n_ker
                str{i} = sprintf('(%s-%s)', obj.kernels{i}.toFileName(), obj.signatures{i}.toFileName());
                if i < n_ker
                    str{i} = [str{i} '-'];
                end
            end
            str = cat(2,str{:});
        end
        function str = toName(obj)
            n_ker = length(obj.kernels); 
            str = cell(1, n_ker);
            for i=1:n_ker
                str{i} = obj.kernels{i}.toName();
                if i < n_ker
                    str{i} = [str{i} '-'];
                end
            end
            str = cat(2,str{:});
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function params = set_params(obj, params)
            n_ker = length(obj.kernels); 
            for i = 1:n_ker
                params = obj.kernels{i}.set_params(params);
            end
            obj.gram_train_ok = 0;
        end
              
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function params = get_params(obj, sigs)
            n_ker = length(obj.kernels); 
            params = cell(n_ker,1);
            for i = 1:n_ker
                params{i} = obj.kernels{i}.get_params(sigs{i}.train_sigs);
            end
            params = cat(1, params{:});
        end  
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        function obj = precompute_gram_matrix(obj, sigs1, sigs2)
            n_ker = length(obj.kernels); 
            if nargin == 1
                for i = 1:n_ker
                    obj.kernels{i}.precompute_gram_matrix();
                end
            else
                for i = 1:n_ker
                    obj.kernels{i}.precompute_gram_matrix(sigs1{i}.train_sigs, sigs2{i});
                end        
            end
            obj.gram_matrix = obj.kernels{1}.gram_matrix;
            for i = 2:n_ker
                obj.gram_matrix = obj.gram_matrix + obj.kernels{i}.gram_matrix;
            end              
        end   
        
        %------------------------------------------------------------------
        % Compute the gram matrix from stored signatures
        function obj = gram_matrix_from_stored_sigs(obj)
            if obj.precompute
                obj.precompute_gram_matrix();
                obj.gram_file = obj.disk_write_gram_matrix();            
            end
        end       

        %------------------------------------------------------------------
        % Get sigs
        function new_sigs = get_kernel_sigs(obj, sigs)
            new_sigs = (1:size(sigs{1},1))';
        end   
        
        %------------------------------------------------------------------
        % Compute the gram matrix from stored signatures
        function obj = compute_gram_matrix(obj, sigs1, sigs2)
            obj.gram_train_ok = 0;
            obj.precompute_gram_matrix(sigs1, sigs2);
            obj.disk_write_gram_matrix();             
        end          
    end
end

