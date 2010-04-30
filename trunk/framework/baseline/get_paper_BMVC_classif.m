
function [classif_BOF classif_PYR points_BOF points_PYR] = get_paper_BMVC_classif(root_BOF, root_PYR, case_C, concatenate)
    if nargin == 0
        root_BOF = [];
        root_PYR = [];
    end
    L = 2;
    sizes = struct('size', {256 512 1024 2048 4096}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]' '[0 0 1]' '[0 0.8 0.8]' '[0 0.8 0.1]'});
    %sizes = struct('size', {256 512 1024 2048}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]' '[0 0 1]' '[0 0.8 0.8]'});
    %sizes = struct('size', {256 512 1024}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]' '[0 0 1]'});
    %sizes = struct('size', {4096}, 'property', 'color', 'prop_val', {'[0 0.8 0.1]'});
    if case_C
        if concatenate
            kernels = struct('kernel', {Linear(1) RBF(-1,1) Intersection(1) Chi2(-1,1)}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
        else
            kernels = struct('kernel', {{Linear(1) Linear(1)} {RBF([],1) RBF([],1)} {Intersection(1) Intersection(1)} {Chi2([],1) Chi2([],1)}}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
        end
        %kernels = struct('kernel', {{Linear(1) Linear(1)}}, 'norm', {L2}, 'property', 'marker', 'prop_val', {'''+'''});   
    else
        kernels = struct('kernel', {Linear(1) RBF([],1) Intersection(1) Chi2([],1)}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
        %kernels = struct('kernel', {Chi2([],1)}, 'norm', {L1}, 'property', 'marker', 'prop_val', {'''+'''});   
    end
    
    [classif_BOF points_BOF] = make_sumup_BOF(root_BOF, sizes, kernels, case_C, concatenate);
    [classif_PYR points_PYR] = make_sumup_PYR(root_PYR, sizes, kernels, L, case_C, concatenate);
end