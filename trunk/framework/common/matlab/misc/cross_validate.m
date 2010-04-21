function [best_params results] = cross_validate(obj, K)
    % Compute K-fold cross validation
    % obj should be a class derived from CrossValidateAPI
    
    global USE_PARALLEL;
    
    params = obj.CV_get_params(); 

    if ~isempty(params)
        n_params = length(params);
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
        
        pg = ProgressBar('Training', 'Cross-validation...');

        % Do K-fold cross-validation
        if USE_PARALLEL
            common = struct('K', K, 'samples', obj.CV_get_training_samples(), 'obj', obj');
            results = run_in_parallel('K_cross_validate_parallel', common, full_params, 0, 0, pg, 0, 1);
        else
            results = K_cross_validate(obj, K, obj.CV_get_training_samples(), full_params, pg);
        end

        best_params = full_params(floor(median(find(results == max(results)))),:);
       
        results
        if length(n_pos) > 1
            results = reshape(results,n_pos');
        end
         
        pg.close();
    end
end