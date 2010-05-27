function [perf std_dev] = K_cross_validate(obj, K, samples, params, pg)
    % Compute folds
    n_samples = size(samples,2);
    folds = cell(K,1);
    for i=1:n_samples
        folds{1+mod(i,K)} = [folds{1+mod(i,K)}; i];
    end
    
    % Do cross-validation
    n_params = size(params, 1);
    perf = zeros(n_params,2);
    std_dev = zeros(n_params,2);
    for i=1:n_params
        pg.progress(i/n_params);              
        Kperf = zeros(K, 2);
        for j=1:K
            f = 1:K;
            f(j) = [];
            obj.CV_set_params(params(i,:));
            train = samples(:, cat(1,folds{f}));
            validate = samples(:, folds{j});
            model = obj.CV_train(train);
            [prec acc] = obj.CV_validate(model, validate);
            Kperf(j,:) = [prec acc];
        end
        perf(i,:) = mean(Kperf);
        dev = Kperf-repmat(perf(i,:),K,1);
        std_dev(i,:) = sqrt(sum(dev.*dev) / (K-1));
    end   
end