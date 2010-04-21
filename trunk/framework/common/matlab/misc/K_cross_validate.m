function results = K_cross_validate(obj, K, samples, params, pg)
 
    % Compute folds
    n_samples = size(samples,1);
    folds = cell(K,1);
    for i=1:n_samples
        folds{1+mod(i,K)} = [folds{1+mod(i,K)}; i];
    end
    
    % Do cross-validation
    n_params = size(params, 1);
    results = zeros(n_params,1);
    for i=1:n_params
        pg.progress(i/n_params);              
        Kperf = zeros(K, 1);
        for j=1:K
            f = 1:K;
            f(j) = [];
            obj.CV_set_params(params(i,:));
            train = samples(cat(1,folds{f}),:);
            validate = samples(folds{j},:);
            model = obj.CV_train(train);
            Kperf(j) = obj.CV_validate(model, validate);
        end
        results(i) = mean(Kperf);
    end   
end