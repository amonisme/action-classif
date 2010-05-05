function [classif points] = make_sumup_PYR(root, sizes, kernels, L, case_C, concatenate, full_grid)
    levels = (0:L)';
    w = 1./2.^(L-levels+1);
    w(1) = 1/2^L;
    grid = [2.^levels, 2.^levels, w];  

    n_sizes = length(sizes);
    n_ker = length(kernels);

    classif = cell(n_sizes, n_ker); 
    points = prepare_points_for_plot(n_sizes*n_ker);
    
    for i = 1:n_sizes
        for j = 1:n_ker
            if case_C
                if concatenate
                    k = {kernels(j).kernel};
                else
                    k = {kernels(j).kernel{1} kernels(j).kernel{2}};
                end                
                if full_grid
                    classif{i,j} = SVM({BOF(MS_Dense(), SIFT(L2Trunc()), sizes(i).size, kernels(j).norm, grid, 1), ...
                                        BOF(MS_Dense(), SIFT(L2Trunc()), sizes(i).size, kernels(j).norm, grid, 0)}, ...
                                        k, 'OneVsAll', [], 1, 5);
                else
                    classif{i,j} = SVM({BOF(MS_Dense(), SIFT(L2Trunc()), sizes(i).size, kernels(j).norm, grid, 1), ...
                                        BOF(MS_Dense(), SIFT(L2Trunc()), sizes(i).size, kernels(j).norm, [],  -1)}, ...
                                        k, 'OneVsAll', [], 1, 5);
                end
            else        
                classif{i,j} = SVM({BOF(MS_Dense(), SIFT(L2Trunc()), sizes(i).size, kernels(j).norm, grid)},{kernels(j).kernel}, 'OneVsAll', [], 1, 5);
            end
            if ~isempty(root)
                d =  classif{i,j}.toFileName();
                [cv_score cv_stdev] = get_cv_score(root, d);
                points((i-1)*n_ker+j).X = 100 - get_prec_acc(root, d);
                points((i-1)*n_ker+j).Y = 100 - cv_score;
                points((i-1)*n_ker+j).stdev = cv_stdev;            
                eval(sprintf('points((i-1)*n_ker+j).%s = %s;', sizes(i).property, sizes(i).prop_val));
                eval(sprintf('points((i-1)*n_ker+j).%s = %s;', kernels(j).property, kernels(j).prop_val));
            end
        end
    end
    classif = reshape(classif, numel(classif), 1);
end