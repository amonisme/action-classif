classdef CrossValidateAPI < handle
    % API for K-fold cross-validation
    
    methods (Abstract)
        % Retrieves the training samples used for K-fold
        samples = CV_get_training_samples(obj)
        
        % Retrieves all the values to test for cross-validation
        % 'params' must be a cell of vectors.
        params = CV_get_params(obj)
        
        % Set parameters
        obj = CV_set_params(obj, params);
        
        % Train on K-1 folds (stored in 'samples') with some value of parameters
        model = CV_train(obj, samples)
        
        % Validate on the remaining fold
        score = CV_validate(model, samples)
    end
end

