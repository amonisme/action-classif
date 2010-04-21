classdef Chi2 < KernelAPI
    
    properties (SetAccess = protected, GetAccess = protected)
        a
        param_cv    % remember which parameterter was cross-validated
    end

    methods (Static = true)
        %------------------------------------------------------------------
        function obj = loadobj(a)
            obj = a;
            if ~isfield(a, 'param_cv')
                obj.param_cv = [1];
            end
        end      
    end
    
    methods        
        %------------------------------------------------------------------
        % Constructor Kernel type: exp(-1/a*Chi2(X,Y)^2)
        function obj = Chi2(a,precompute,lib)
            if(nargin < 1)
                a = [];
            end
            if(nargin < 2)
                precompute = 0;
            end
            if(nargin < 3)
                lib = 'svmlight';
            end
            
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
                throw(MException('',['Unknown library for Chi2 kernel: "' lib '".\nPossible values are: "svmlight".\n']));
            end
        end
        
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1) (precomputed is [] or
        % the file containing the data.)
        function svm = lib_call_learn(obj, C, J, labels, sigs)
            svm = svmlearn(sigs, labels, sprintf('-v 0 -c %s -j %s -t 4 -g %s -u1',num2str(C), num2str(J), num2str(1/obj.a)));
        end
        
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        function score = lib_call_classify(obj, svm, sigs)
            [err score] = svmclassify(sigs, zeros(size(sigs,1),1), svm);
        end        
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        function str = toString(obj)
            str = sprintf('Chi2 kernel: exp(-1/%s*Chi2(X,Y)^2)',num2str(obj.a));
        end
        function str = toFileName(obj)
            if obj.param_cv(1)
                a = '?';
            else
                a = num2str(obj.a);
            end
            str = sprintf('Chi2[%s]',a);
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
            do_cv = false;
            if isempty(obj.a)
                dist = obj.get_chi2_dist(training_sigs);
                val_a = mean(mean(dist)) * (1.5.^(-3:3));
                do_cv = true;
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
            if nargin<3
                sigs1 = [zeros(1,size(sigs1,2)); sigs1];
            
                obj.gram_matrix = exp( - obj.get_chi2_dist(sigs1) / obj.a);                
            else
                sigs1 = [zeros(1,size(sigs1,2)); sigs1];
                sigs2 = [zeros(1,size(sigs2,2)); sigs2];
            
                obj.gram_matrix = exp( - obj.get_chi2_dist(sigs1, sigs2) / obj.a);                
            end            
        end        
    end
    
    methods (Static)        
        %------------------------------------------------------------------
        % Internal method for pre-computing chi2 distance between each
        % histogram
        function dist = get_chi2_dist(sigs1, sigs2)
            if nargin<2
                sigs2 = sigs1;
                is_symetric = 1;
            else
                is_symetric = 0;
            end
            
            n1 = size(sigs1, 1);
            n2 = size(sigs2, 1);
            d  = size(sigs1, 2);
            
            % precompute the chi2 distances
            dist = zeros(n1, n2);
%             
%             tic
%             for k = 1:d
%                 t = toc;
%                 fprintf('%f\n', t*d/k); 
%                 A = repmat(sigs1(:,k),1,n2);
%                 B = repmat(sigs2(:,k)',n1,1);
%                 N = A - B;
%                 D = A + B + eps;
%                 dist = dist + N.*N./D;
%             end
            
%             sigs2sparse = cell(n2,1);
%             for j=1:n2
%                 sigs2sparse{j} = sparse(sigs2(j,:));
%             end
% 
%             tic
%             for i=1:n1
%                 sigs1sparse = sparse(sigs1(i,:));
%                 t = toc;
%                 fprintf('%fs\n', t*n1/i);
%                 if is_symetric
%                     dist(i,i) = 0;
%                     js = (i+1):n2;
%                 else
%                     js = 1:n2;
%                 end
%                 for j=js
%                     S = sigs1sparse + sigs2sparse{j};
%                     I = S ~= 0;
%                     D = sigs1(i,I) - sigs2(j,I);
%                     dist(i,j) = sum(D.*D ./ S(I));
%                     if is_symetric
%                         dist(j,i) = dist(i,j);
%                     end
%                 end
%             end

            for i=1:n1               
                I = (sigs1(i,:) ~= 0);
                rest = sum(abs(sigs2(:,~I)), 2);
                s1 = sigs1(i,I);
                s2 = sigs2(:,I);
                
                if is_symetric
                    dist(i,i) = 0;
                end

                for j=1:n2
                    if ~is_symetric || j > i 
                        S = s1 + s2(j,:);
                        D = s1 - s2(j,:);
                        dist(i,j) = sum(D.*D ./ S) + rest(j);
                        if is_symetric
                            dist(j,i) = dist(i,j);
                        end
                    end
                end
            end    
            
            dist = dist * 2;
        end        
    end  
end

