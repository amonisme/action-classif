function perf = compare_get_dim(perf_orig, dim)
    if dim == 0
        perf = reshape(perf_orig, numel(perf_orig), 1);
        I = (perf ~= -1);
        perf = {perf(I)};
    else
        d = size(perf_orig, dim);
        perf = cell(d,1);
        for i = 1:d
            m = get_perf_dim(perf_orig, dim, i);
            m = reshape(m, numel(m), 1);
            I = (m ~= -1);
            perf{i} = m(I);
        end
    end
end

function perf = get_perf_dim(perf, dim, i)
    switch dim
        case 1
            perf = perf(i,:,:,:,:);
        case 2
            perf = perf(:,i,:,:,:);
        case 3
            perf = perf(:,:,i,:,:);
        case 4
            perf = perf(:,:,:,i,:);
        case 5
            perf = perf(:,:,:,:,i);
    end    
end
