function [params best_params prec sd_prec acc sd_acc] = cross_validate(obj, K)
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
        if USE_PARALLEL && 0
            common = struct('K', K, 'samples', obj.CV_get_training_samples(), 'obj', obj');
            results = run_in_parallel('K_cross_validate_parallel', common, full_params, 0, 0, pg, 0, 1);
            perf = results(:,1:2);
            std_dev = results(:,3:4);            
        else
            [perf std_dev] = K_cross_validate(obj, K, obj.CV_get_training_samples(), full_params, pg);
        end

        optimize_with = perf(:,1);  % optimize precision
        %optimize_with = perf(:,2); % optimize accuracy
        
        best_params = full_params(floor(median(find(optimize_with == max(optimize_with)))),:);
       
        prec = perf(:,1);
        acc  = perf(:,2);
        sd_prec = std_dev(:,1);
        sd_acc  = std_dev(:,2);
        
        if length(n_pos) > 1
            prec = reshape(prec,n_pos');
            acc  = reshape(acc,n_pos');
            sd_prec = reshape(sd_prec,n_pos');
            sd_acc  = reshape(sd_acc,n_pos');
        end  
    else
        best_params = params;
        prec = [];
        sd_prec = [];
        acc = [];
        sd_acc = [];
    end
    pg.close();    
end