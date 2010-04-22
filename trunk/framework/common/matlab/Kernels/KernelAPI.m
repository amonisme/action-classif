classdef KernelAPI < handle
    properties % (SetAccess = protected, GetAccess = protected)
        precompute      % does the kernel precomputes the gram matrix and send it to the lib?
        gram_matrix     % the gram matrix
        gram_file       % the path of the gram matrix file
        sigs            % For cross validation, it is useful to remember the signatures
        lib_name
        lib
    end
    
    methods
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = learn(obj, C, J, labels, sigs)            
            if obj.precompute 
                if obj.lib == 0
                    svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 4 -u0%s',num2str(C), num2str(J), obj.gram_file));
                end
            else            
                svm = obj.lib_call_learn(C, J, labels, sigs);
            end
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = classify(obj, svm, sigs)           
            if obj.precompute
                if obj.lib == 0
                    [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);
                end
            else
                score = obj.lib_call_classify(svm, sigs);
            end            
        end
        
        %------------------------------------------------------------------
        % Store the gram matrix into a file
        function file = disk_write_gram_matrix(obj)            
            global FILE_BUFFER_PATH;

            % save the distances
            file = fullfile(FILE_BUFFER_PATH,'gram_matrix.txt');
            fid = fopen(file, 'w+');
            fwrite(fid, size(obj.gram_matrix, 1), 'int32');
            fwrite(fid, size(obj.gram_matrix, 2), 'int32');
            fwrite(fid, obj.gram_matrix', 'double');
            fclose(fid);
        end
        
        %------------------------------------------------------------------
        % Store the signatures and possibly precompute distances (examples
        % Chi2)
        function prepare_cross_validation(obj, sigs)
            if obj.precompute
                obj.sigs = sigs;               
            end
        end  
        
        %------------------------------------------------------------------
        % Get sigs
        function new_sigs = get_kernel_sigs(obj, sigs)
            if obj.precompute
                new_sigs = (1:size(sigs,1))';
            else
                new_sigs = sigs;
            end              
        end          
        
        %------------------------------------------------------------------
        % Compute the gram matrix from stored signatures
        function obj = gram_matrix_from_stored_sigs(obj)
            if obj.precompute
                obj.precompute_gram_matrix(obj.sigs);
                obj.gram_file = obj.disk_write_gram_matrix();              
            end
        end    
        
        %------------------------------------------------------------------
        % Compute the gram matrix from stored signatures
        function obj = compute_gram_matrix(obj, sigs1, sigs2)
            if obj.precompute
                if nargin < 3
                    obj.precompute_gram_matrix(sigs1);
                else
                    obj.precompute_gram_matrix(sigs1, sigs2);
                end
                obj.gram_file = obj.disk_write_gram_matrix();              
            end
        end            
        
        %------------------------------------------------------------------
        % Prepare for cross-validation and enerate testing values of
        % parameters for cross validation (do_cv is boolean, indicates
        % whether cross_validation is needed)
        function params = CV_get_params(obj, training_sigs)
            obj.prepare_cross_validation(training_sigs);
            params = obj.get_params();
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function obj = CV_set_params(obj, params)
            p = obj.get_params();
            n_params = size(p,1);
            current_params = zeros(1,n_params);
            
            for i=1:n_params
                pi = p{i};
                current_params = pi(1);
            end
            
            if ~isempty(find(current_params ~= params,1)) || isempty(obj.gram_matrix);
                obj.set_params(params);
                obj.gram_matrix_from_stored_sigs();                        
            end            
        end        
    end
    
    methods (Abstract)
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        svm = lib_call_learn(obj, C, J, labels, sigs)
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        score = lib_call_classify(obj, svm, sigs)            
                
        %------------------------------------------------------------------
        % Set parameters
        obj = set_params(obj, params)
              
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation (do_cv
        % is boolean, indicates whether cross_validation is needed)
        params = get_params(obj)
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products into the gram matrix
        % such that: gram_matrix(i+1,j+1) = <K(i)|K(j)>
        %            gram_matrix(i,1) = <K(i)|0>
        %            gram_matrix(1,j) = <0|K(j)>
        obj = precompute_gram_matrix(obj, sigs1, sigs2)
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)       
    end
end

