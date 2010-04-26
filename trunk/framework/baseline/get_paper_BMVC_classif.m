function [classif_BOF classif_PYR points_BOF points_PYR] = get_paper_BMVC_classif(root_BOF, root_PYR)
    if nargin == 0
        root_BOF = [];
        root_PYR = [];
    end
    L = 2;
    sizes = struct('size', {256 512 1024 2048 4096}, 'property', 'color', 'prop_val', {'[1 0 0]' '[1 0 1]' '[0 0 1]' '[0 0.8 0.8]' '[0 0.8 0.1]'});
    kernels = struct('kernel', {Linear RBF Intersection Chi2}, 'norm', {L2 L2 L1 L1}, 'property', 'marker', 'prop_val', {'''+''' '''o''' '''x''' '''s'''});   
    
    [classif_BOF points_BOF] = make_sumup_BOF(root_BOF, sizes, kernels);
    [classif_PYR points_PYR] = make_sumup_PYR(root_PYR, sizes, kernels, L);
end