classdef Intersection < KernelAPI
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: sum_i(min(Xi, Yi))
        function obj = Intersection(precompute,lib)
            if nargin < 1
                precompute = 1;
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
                throw(MException('',['Unknown library for intersection kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1) (precomputed is [] or
        % the file containing the data.)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
            svm = svmlearn(sigs', labels, sprintf('-v 0 -c %s -j %s -t 4 -u2',num2str(C), num2str(J)));
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
            [err score] = svmclassify(sigs', zeros(size(sigs,2),1), svm);
        end 
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Intersection kernel: $sum_i(min(X_i, Y_i))$');
        end
        function str = toFileName(obj)
            str = 'Inter';
        end
        function str = toName(obj)
            str = 'Inter';
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
            end        
        end  
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        function obj = precompute_gram_matrix(obj, sigs1, sigs2)            
%            load('backup_gram.mat', 'gmat');
%            obj.gram_matrix = gmat;
            
            if nargin > 1
                n1 = size(sigs1,2);
                n2 = size(sigs2,2);
                                
                obj.gram_matrix = zeros(n1+1,n2+1);
                if issparse(sigs1) && issparse(sigs2)
                    for i = 1:n1
                        for j = 1:n2
                            obj.gram_matrix(i+1,j+1) = sum(min(sigs1(:,i), sigs2(:,j)));
                        end
                    end
                else                    
                    for j=1:n2
                        c = min(sigs1, repmat(sigs2(:,j), 1, n1));
                        obj.gram_matrix(2:end,j+1) = sum(c,1)';
                    end
                end
            end
            
            gmat = obj.gram_matrix;
            save('backup_gram.mat', 'gmat');
        end
    end
end

