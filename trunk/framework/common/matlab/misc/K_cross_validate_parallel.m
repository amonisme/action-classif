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
    results = zeros(n_params,2);
    for i=1:n_params
        task_progress(tid, i/n_params);              
        Kperf = zeros(common.K, 2);
        for j=1:common.K
            f = 1:common.K;
            f(j) = [];
            common.obj.CV_set_params(params(i,:));
            train = common.samples(cat(1,folds{f}),:);
            validate = common.samples(folds{j},:);
            model = common.obj.CV_train(train);
            [prec acc] = obj.CV_validate(model, validate);
            Kperf(j,:) = [prec acc];
        end
        results(i,1) = mean(Kperf);
        dev = Kperf-results(i,1);
        results(i,2) = sqrt(sum(dev.*dev) / (length(dev)-1));
        
        perf(i,:) = mean(Kperf);
        dev = Kperf-repmat(perf(i,:),K,1);
        std_dev(i,:) = sqrt(sum(dev.*dev) / (K-1));
    end   
    
    results = [perf std_dev];
    task_close(tid);
end