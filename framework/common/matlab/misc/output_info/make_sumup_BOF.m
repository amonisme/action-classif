function [classif points] = make_sumup_BOF(root, sizes, kernels)
    n_sizes = length(sizes);
    n_ker = length(kernels);

    classif = cell(n_sizes, n_ker);
    points = prepare_points_for_plot(n_sizes*n_ker);
    
    for i = 1:n_sizes
        for j = 1:n_ker
            classif{i,j} = SVM(kernels(j).kernel, BOF(Channels({MS_Dense()}, {SIFT(L2Trunc())}), sizes(i).size, kernels(j).norm), 'OneVsAll', [], 1, 5);
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