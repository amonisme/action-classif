
classdef KernelAPI < handle
    properties (SetAccess = protected)
        precompute      % does the kernel precomputes the gram matrix and send it to the lib?
        gram_matrix     % the gram matrix
        gram_train_ok   % is the gram matrix for training up-to-date?
        gram_file       % the path of the gram matrix file
        lib_name
        lib
    end
    
    methods
        %------------------------------------------------------------------
        % Constructor
        function obj = KernelAPI()
            obj.gram_file = 'gram_matrix';    
            obj.gram_train_ok = 0;
        end
        
        %------------------------------------------------------------------
        % Don't save the gram matrix on disk
        function obj = dont_save_gram(obj)
            obj.gram_file = [];   
            obj.precompute = 1;
        end
                
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1)
        function svm = learn(obj, C, J, labels, sigs)      
            global FILE_BUFFER_PATH;
            
            if obj.precompute 
                if obj.lib == 0
                    if ~obj.gram_train_ok
                        obj.gram_train_ok = 1;
                        obj.precompute_gram_matrix();
                        obj.disk_write_gram_matrix();    
                    end       
                    svm = svmlearn(sigs', labels, sprintf('-v 0 -c %s -j %s -t 4 -u0%s',num2str(C), num2str(J), fullfile(FILE_BUFFER_PATH, obj.gram_file)));
                end
            else            
                svm = obj.lib_call_learn(C, J, labels, sigs);
            end
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = classify(obj, svm, sigs)            
            global FILE_BUFFER_PATH;
            if obj.precompute
                svm.kernel_parm.custom = sprintf('0%s',fullfile(FILE_BUFFER_PATH, obj.gram_file));
                if obj.lib == 0                    
                    [err score] = svmclassify(sigs', zeros(size(sigs,2),1), svm);
                end
            else
                score = obj.lib_call_classify(svm, sigs);
            end            
        end
        
        %------------------------------------------------------------------
        % Store the gram matrix into a file
        function disk_write_gram_matrix(obj)             
            global FILE_BUFFER_PATH;
            if ~isempty(obj.gram_file)
                % save the distances
                file = fullfile(FILE_BUFFER_PATH, obj.gram_file);
                fid = fopen(file, 'w+');
                fwrite(fid, size(obj.gram_matrix, 1), 'int32');
                fwrite(fid, size(obj.gram_matrix, 2), 'int32');
                fwrite(fid, obj.gram_matrix', 'double');
                fclose(fid);
            end
        end
              
        %------------------------------------------------------------------
        % Get sigs
        function new_sigs = get_kernel_sigs(obj, sigs)
            if obj.precompute
                new_sigs = 1:size(sigs,2);
            else
                new_sigs = sigs;
            end              
        end          
        
        %------------------------------------------------------------------
        % Compute the gram matrix from stored signatures
        function obj = compute_gram_matrix(obj, sigs1, sigs2)
            if obj.precompute
                obj.gram_train_ok = 0;               
                obj.precompute_gram_matrix(sigs1, sigs2);
                obj.disk_write_gram_matrix();             
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
        params = set_params(obj, params)
              
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

