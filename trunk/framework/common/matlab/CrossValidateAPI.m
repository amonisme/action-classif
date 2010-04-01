classdef CrossValidateAPI < handle
    % API for K-fold cross-validation
    
    methods (Abstract)
        % Retrieves the training samples used for K-fold
        samples = get_training_samples(obj)
        
        % Retrieves all the values to test for cross-validation
        % 'params' must be a cell of vectors.
        params = get_params(obj)
        
        % Train on K-1 folds (stored in 'samples') with some value of parameters
        model = CV_train(obj, params, samples)
        
        % Validate on the remaining fold
        score = CV_validate(model, samples)
    end
end

