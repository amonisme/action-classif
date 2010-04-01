classdef Chi2 < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
    end

    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: exp(-1/a*Chi2(X,Y)^2)
        function obj = Chi2(a,lib)
            if(nargin < 1)
                a = [];
            end
            if(nargin < 2)
                lib = 'svmlight';
            end
            
            obj.a = a;
            obj.lib_name = lib;
            if(strcmpi(lib, 'svmlight'))
                obj.lib = 0;
            else
                throw(MException('',['Unknown library for Chi2 kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1) (precomputed is [] or
        % the file containing the data.)
        function svm = learn(obj, C, J, labels, sigs, precomputed)
            if isempty(precomputed)
                p = 0;
                file = [];
            else
                p = 1;
                file = sprintf('%s/%s', cd, precomputed);
            end
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 4 -g %s -u0%d%s',num2str(C), num2str(J), num2str(1/obj.a), p, file));
        end
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Chi2 kernel: exp(-1/%s*Chi2(X,Y)^2)',num2str(obj.a));
        end
        function str = toFileName(obj)
            str = sprintf('Chi2[A(%s)]',num2str(obj.a));
        end
        function str = toName(obj)
            str = 'Chi2';
        end
        
        %------------------------------------------------------------------
        % Set parameters
        function obj = set_params(obj, params)
            obj.a = params(1);
        end
              
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation
        function [params do_cv] = get_testing_params(obj, training_sigs)
            dist = obj.get_chi2_dist(training_sigs);
            do_cv = false;
            if isempty(obj.a)
                val_a = mean(mean(dist)) * (1.5.^(-3:3));
                do_cv = true;
            else
                val_a = obj.a;
            end
            params = {val_a'}';
        end  
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products for cross-validation
        % If precomputation not supported, returns [], otherwise, returns
        % the path to file where results are saved
        function file = precompute(obj, training_sigs)
            file = [];
%             global FILE_BUFFER_PATH;
%             dist = obj.get_chi2_dist(training_sigs);
%             for i=1:n_histo
%                 dist(i,i) = sum(training_sigs(i,:)) * 2;
%             end  
% 
%             % save the distances
%             file = sprintf('%sdist.txt',FILE_BUFFER_PATH);
%             fid = fopen(file, 'w+');
%             fwrite(fid, size(dist, 1), 'int32');
%             fwrite(fid, dist, 'double');
%             fclose(fid);
        end
    end
    
    methods (Static)
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = classify(svm, sigs, precomputed)
            [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);
        end
        
        %------------------------------------------------------------------
        % Internal method for pre-computing chi2 distance between each
        % histogram
        function dist = get_chi2_dist(histo)
            n_histo = size(histo, 1);
            % precompute the chi2 distances
            dist = zeros(n_histo);
            for i=1:n_histo
                for j=(i+1):n_histo
                    nums = histo(i,:) - histo(j,:);
                    dens = abs(histo(i,:) + histo(j,:));
                    dens(dens(:,:) == 0) = 1;
                    dist(i,j) = sum(nums.*nums./dens);
                    dist(j,i) = dist(i,j);
                end
            end                   
            dist = dist * 2;
        end        
    end  
end

