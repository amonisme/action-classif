function [classif_BOF classif_PYR points_BOF points_PYR] = get_paper_BMVC_classif(root_BOF, root_PYR, case_C, no_cv, concatenate, full_grid)
    if nargin == 0
        root_BOF = [];
        root_PYR = [];
    end
    if no_cv
        kernel_cv_value = -1;
    else
        kernel_cv_value = [];
    end
    
    L = 2;
    sizes = struct('size', {256 512 1024 2048 4096}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]' '[0 0 1]' '[0 0.8 0.8]' '[0 0.8 0.1]'});
    %sizes = struct('size', {256 512 1024 2048}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]' '[0 0 1]' '[0 0.8 0.8]'});
    %sizes = struct('size', {256 512}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]'});
    %sizes = struct('size', {512}, 'property', 'color', 'prop_val', {'[1 0 1]'});
    if case_C
        if concatenate
            kernels = struct('kernel', {Linear(1) RBF(kernel_cv_value,1) Intersection(1) Chi2(kernel_cv_value,1)}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
            %kernels = struct('kernel', {Linear(1)}, 'norm', {L1}, 'property', 'marker', 'prop_val', {'''x'''});   
        else
            kernels = struct('kernel', {{Linear(1) Linear(1)} {RBF(kernel_cv_value,1) RBF(kernel_cv_value,1)} {Intersection(1) Intersection(1)} {Chi2(kernel_cv_value,1) Chi2(kernel_cv_value,1)}}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
            %kernels = struct('kernel', {{Intersection(1) Intersection(1)}}, 'norm', {L1}, 'property', 'marker', 'prop_val', {'''x'''});   
        end
        
    else
        kernels = struct('kernel', {Linear(1) RBF(kernel_cv_value,1) Intersection(1) Chi2(kernel_cv_value,1)}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
        %kernels = struct('kernel', {Intersection(1)}, 'norm', {L1}, 'property', 'marker', 'prop_val', {'''s'''});   
    end
    
    [classif_BOF points_BOF] = make_sumup_BOF(root_BOF, sizes, kernels, L, case_C, concatenate, full_grid);
    [classif_PYR points_PYR] = make_sumup_PYR(root_PYR, sizes, kernels, L, case_C, concatenate, full_grid);
end