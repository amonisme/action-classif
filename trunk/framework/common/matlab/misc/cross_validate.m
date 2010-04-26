function [best_params results std_dev] = cross_validate(obj, K)
    % Compute K-fold cross validation
    % obj should be a class derived from CrossValidateAPI
    
    global USE_PARALLEL;
    
    pg = ProgressBar('Training', 'Cross-validation...');
            
    params = obj.CV_get_params();
    n_params = length(params);
    
    do_cv = 0;
    for i=1:n_params
        if length(params{i}) > 1
            do_cv = 1;
            break;
        end
    end
    
    if do_cv        
        n_pos = zeros(n_params, 1);
        for i=1:n_params
            n_pos(i) = length(params{i});
        end
       
        % Generating parameters
        full_params = params{1};
        for i = 2:n_params
            n1 = size(params{i},1);
            n2 = size(full_params,1);
            full_params = [repmat(full_params, n1, 1) kron(params{i},ones(n2,1))];
        end
        
        % Do K-fold cross-validation
        if USE_PARALLEL
            common = struct('K', K, 'samples', obj.CV_get_training_samples(), 'obj', obj');
            results = run_in_parallel('K_cross_validate_parallel', common, full_params, 0, 0, pg, 0, 1);
            std_dev = results(:,2);
            results = results(:,1);
        else
            [results std_dev] = K_cross_validate(obj, K, obj.CV_get_training_samples(), full_params, pg);
        end

        best_params = full_params(floor(median(find(results == max(results)))),:);
       
        if length(n_pos) > 1
            results = reshape(results,n_pos');
            std_dev = reshape(std_dev,n_pos');
        end  
    else
        best_params = params;
        results = [];
    end
    pg.close();    
end