classdef Kmeans < handle
    
    properties (SetAccess = protected, GetAccess = protected)
        K       % Number of centers
        lib     % Name of the lib
        lib_id  % id of the lib
        maxiter % Maximum number of iterations allowed
        points  % store the points to cluster (one per column)
    end
    
    methods
        %------------------------------------------------------------------        
        function obj = Kmeans(num_centers, library, maxiter)
            obj.K = num_centers;
            obj.lib = library;
            obj.maxiter = maxiter;
            
            if(strcmpi(library, 'vlfeat'))
                obj.lib_id = 0;
            else
                if(strcmpi(library, 'vgg'))
                    obj.lib_id = 1;
                else
                    if(strcmpi(library, 'matlab'))
                        obj.lib_id = 2;
                    else
                        if(strcmpi(library, 'mex'))
                            obj.lib_id = 3;
                        else
                            if(strcmpi(library, 'cpp'))
                                obj.lib_id = 4;
                            else                            
                                throw(MException('',['Unknown library for computing K-means: "' library '".\nPossible values are: "vlfeat", "vgg", "matlab", "mex" and "cpp".\n']));
                            end
                        end
                    end
                end
            end            
        end
               
        %------------------------------------------------------------------
        % prepare kmeans computation (one point per column)
        function prepare_kmeans(obj, points)
            global FILE_BUFFER_PATH;
  
            switch obj.lib_id
                case 0  % vlfeat
                    m = max(max(points));
                    obj.points = uint8(255/m*points);
                case {1, 3}  % vgg & mex
                    obj.points = points;
                case 2  % matlab
                    obj.points = points';
                case 4  % cpp             	
                    file_in = fullfile(FILE_BUFFER_PATH,'input.txt'); % if modified, modifiy also line 133 

                    dimension = size(points, 1);
                    n_data = size(points, 2);

                    % Save data
                    fid = fopen(file_in, 'w+');
                    fwrite(fid, dimension, 'int32');
                    fwrite(fid, n_data, 'int32');
                    fwrite(fid, points, 'double');
                    fclose(fid);
                    
                    obj.points = dimension;
            end
        end
        
        %------------------------------------------------------------------
        function centers = do_kmeans(obj, file)
            if nargin >= 3 && exist(file,'file') == 2
                load(file,'centers');
                if exist('centers','var') ~= 1
                    load(file,'c');
                    if exist('c','var') == 1
                        centers = c;
                        save(file, 'centers');
                    end
                end
            end
            if exist('centers','var') ~= 1
                switch obj.lib_id
                case 0  % vlfeat
                    centers = obj.vlfeat(obj.K, obj.maxiter);
                case 1  % vgg
                    centers = obj.vgg(obj.K, obj.maxiter);
                case 2  % matlab
                    centers = obj.matlab(obj.K, obj.maxiter);
                case 3  % mex
                    centers = obj.mex(obj.K, obj.maxiter);
                case 4  % cpp             	
                    centers = obj.cpp(obj.K, obj.maxiter);
                end
                if nargin >= 3
                    save(file, 'centers');
                end
            end
            
            obj.points = [];
        end    
        
        %------------------------------------------------------------------
        function l = get_lib(obj)
            l = obj.lib;
        end
    
        %------------------------------------------------------------------
        function centers = vlfeat(obj, K, maxiter)
            centers = vl_ikmeans(obj.points, K, 'MaxIters', maxiter);
            centers = m/255*double(centers');            
        end
        
        %------------------------------------------------------------------
        function centers = vgg(obj, K, maxiter)
            centers = vgg_kmeans(obj.points, K, maxiter)';            
        end
        
        %------------------------------------------------------------------
        function centers = matlab(obj, K, maxiter)
            [id centers] = kmeans(obj.points, K, 'emptyaction', 'singleton','onlinephase','off');
        end
        
        %------------------------------------------------------------------
        function centers = mex(obj, K, maxiter)
            centers = kmeans_mex(obj.points, K, maxiter);
            centers = centers';            
        end
        
        %------------------------------------------------------------------
        function centers = cpp(obj, K, maxiter)
            global FILE_BUFFER_PATH LIB_DIR;
            
            file_in = fullfile(FILE_BUFFER_PATH,'input.txt');
            file_out = fullfile(FILE_BUFFER_PATH,'output.txt');
                        
            % Do kmeans
            cmd = fullfile(LIB_DIR, 'kmeans', sprintf('kmeans_cpp %s %d %d %s', file_in, K, maxiter, file_out));
            system(cmd);
            
            % Load data
            fid = fopen(file_out, 'r');
            centers = fread(fid, K*obj.points, 'double');   % hack: obj.points is the dimension of the points
            fclose(fid);
            centers = reshape(centers, obj.points, K)';     % hack: obj.points is the dimension of the points
        end
        %------------------------------------------------------------------
    end    
end

