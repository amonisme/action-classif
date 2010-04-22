classdef Kmeans < handle
    
    properties (SetAccess = protected, GetAccess = protected)
        K       % Number of centers
        fun     % handle of the function for computing Kmeans (depends of the lib)
        lib     % Name of the lib
        maxiter % Maximum number of iterations allowed
    end
    
    methods
        %------------------------------------------------------------------        
        function obj = Kmeans(num_centers, library, maxiter)
            obj.K = num_centers;
            obj.lib = library;
            obj.maxiter = maxiter;
            
            if(strcmpi(library, 'vlfeat'))
                obj.fun = @Kmeans.vlfeat;
            else
                if(strcmpi(library, 'vgg'))
                    obj.fun = @Kmeans.vgg;
                else
                    if(strcmpi(library, 'matlab'))
                        obj.fun = @Kmeans.matlab;
                    else
                        if(strcmpi(library, 'mex'))
                            obj.fun = @Kmeans.mex;
                        else
                            if(strcmpi(library, 'cpp'))
                                obj.fun = @Kmeans.cpp;
                            else                            
                                throw(MException('',['Unknown library for computing K-means: "' library '".\nPossible values are: "vlfeat", "vgg", "matlab", "mex" and "cpp".\n']));
                            end
                        end
                    end
                end
            end            
        end
               
        %------------------------------------------------------------------
        function centers = do_kmeans(obj, points, file)  
            if nargin >= 3 && exist(file,'file') == 2
                load(file,'centers');
                if exist('centers','var') ~= 1
                    load(file,'c');
                    if exist('c','var') == 1
                        centers = c;
                        save(file, 'centers');
                    end
                end
                if exist('centers','var') ~= 1
                    centers = obj.fun(points, obj.K, obj.maxiter);
                    save(file, 'centers');
                end
            else
                centers = obj.fun(points, obj.K, obj.maxiter);
                if nargin >= 3
                    save(file, 'centers');
                end
            end
        end    
        
        %------------------------------------------------------------------
        function l = get_lib(obj)
            l = obj.lib;
        end
    end
    
    methods (Static)
        %------------------------------------------------------------------
        function centers = vlfeat(points, K, maxiter)
            m = max(max(points));
            points = uint8(255/m*points);
            centers = vl_ikmeans(points', K, 'MaxIters', maxiter);
            centers = m/255*double(centers');            
        end
        
        %------------------------------------------------------------------
        function centers = vgg(points, K, maxiter)
            centers = vgg_kmeans(points', K, maxiter)';            
        end
        
        %------------------------------------------------------------------
        function centers = matlab(points, K, maxiter)
            [id centers] = kmeans(points, K, 'emptyaction', 'singleton','onlinephase','off');
        end
        
        %------------------------------------------------------------------
        function centers = mex(points, K, maxiter)
            centers = kmeans_mex(points', K, maxiter);
            centers = centers';            
        end
        
        %------------------------------------------------------------------
        function centers = cpp(points, K, maxiter)
            global FILE_BUFFER_PATH LIB_DIR;

            file_in = fullfile(FILE_BUFFER_PATH,'input.txt');
            file_out = fullfile(FILE_BUFFER_PATH,'output.txt');
            
            dimension = size(points, 2);
            n_data = size(points, 1);
            points = reshape(points', 1, dimension*n_data);
            
            % Save data
            fid = fopen(file_in, 'w+');
            fwrite(fid, dimension, 'int32');
            fwrite(fid, n_data, 'int32');
            fwrite(fid, points, 'double');
            fclose(fid);
            
            % Do kmeans
            cmd = fullfile(LIB_DIR, 'kmeans', sprintf('kmeans_cpp %s %d %d %s', file_in, K, maxiter, file_out));
            system(cmd);
            
            % Load data
            fid = fopen(file_out, 'r');
            centers = fread(fid, K*dimension, 'double');
            fclose(fid);
            centers = reshape(centers, dimension, K)';
        end
        %------------------------------------------------------------------
    end    
end

