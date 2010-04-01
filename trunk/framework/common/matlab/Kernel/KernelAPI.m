classdef KernelAPI
    properties (SetAccess = protected, GetAccess = protected)
        lib_name
        lib
    end
    
    methods (Abstract)       
        %------------------------------------------------------------------
        % Return a trained svm (labels are 1 or -1) (precomputed is [] or
        % the file containing the data.)
        svm = learn(obj, C, J, labels, sigs, precomputed)
                
        %------------------------------------------------------------------
        % Set parameters
        obj = set_params(obj, params)
              
        %------------------------------------------------------------------
        % Generate testing values of parameters for cross validation (do_cv
        % is boolean, indicates whether cross_validation is needed)
        [params do_cv] = get_testing_params(obj, training_sigs)
        
        %------------------------------------------------------------------
        % Precompute distances or scalar products for cross-validation
        % If precomputation not supported, returns [], otherwise, returns
        % the path to file where results are saved
        file = precompute(obj, training_sigs)
        
        %------------------------------------------------------------------
        % Describe parameters as text or filename:
        str = toString(obj)
        str = toFileName(obj)
        str = toName(obj)
    end
    
    methods (Static)
        %------------------------------------------------------------------
        % Return scores provided a trained svm
        score = classify(svm, sigs, precomputed)
    end
end

