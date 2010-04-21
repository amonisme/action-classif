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
        function svm = learn(obj, C, J, labels, sigs, use_precomputed_gram_matrix)
            if nargin < 4
                use_precomputed_gram_matrix = 0;
            end     
            
            if obj.precompute 
                if obj.lib == 0
                    if ~use_precomputed_gram_matrix
                        obj.sigs = sigs;
                        obj.precompute_gram_matrix(sigs);
                        obj.gram_file = obj.disk_write_gram_matrix();
                        sigs = (1:size(sigs,1))';                        
                    end
                    svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 4 -u0%s',num2str(C), num2str(J), obj.gram_file));   
                end
            else
                svm = obj.lib_call_learn(C, J, labels, sigs);
            end
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = classify(obj, svm, sigs, use_precomputed_gram_matrix)
            if nargin < 4
                use_precomputed_gram_matrix = 0;
            end
            
            if obj.precompute
                if obj.lib == 0
                    if ~use_precomputed_gram_matrix
                        obj.precompute_gram_matrix(obj.sigs, sigs);
                        obj.disk_write_gram_matrix();
                        sigs = (1:size(sigs,1))';                        
                    end
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
            fwrite(fid, obj.gram_matrix, 'double');
            fclose(fid);
        end
        
        %------------------------------------------------------------------
        % Store the signatures
        function new_sigs = prepare_cross_validation(obj, sigs)
            obj.sigs = sigs;
            if obj.precompute
                new_sigs = (1:size(sigs,1))';
            else
                new_sigs = sigs;
            end                
        end        
        
        %------------------------------------------------------------------
        % Compute the gram matrix from stored signatures
        function obj = gram_matrix_from_stored_sigs(obj)
            obj.precompute_gram_matrix(obj.sigs);
            if obj.lib == 0
                obj.gram_file = obj.disk_write_gram_matrix();
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
        [params do_cv] = get_testing_params(obj, training_sigs)
        
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

