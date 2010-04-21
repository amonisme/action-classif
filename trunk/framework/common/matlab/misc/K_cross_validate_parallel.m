function results = K_cross_validate_parallel(common, params)
    tid = task_open();
        
    % Compute folds
    n_samples = size(common.samples,1);
    folds = cell(common.K,1);
    for i=1:n_samples
        folds{1+mod(i,common.K)} = [folds{1+mod(i,common.K)}; i];
    end

    % Do cross-validation
    n_params = size(params, 1);
    results = zeros(n_params,1);
    for i=1:n_params
        task_progress(tid, i/n_params);              
        Kperf = zeros(common.K, 1);
        for j=1:common.K
            f = 1:common.K;
            f(j) = [];
            common.obj.CV_set_params(params(i,:));
            train = common.samples(cat(1,folds{f}),:);
            validate = common.samples(folds{j},:);
            model = common.obj.CV_train(train);
            Kperf(j) = common.obj.CV_validate(model, validate);
        end
        results(i) = mean(Kperf);
    end   
    
    task_close(tid);
end