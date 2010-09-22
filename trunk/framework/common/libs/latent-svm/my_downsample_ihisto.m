function subhisto = my_downsample_ihisto(histo, target_size, target_sbin)    
    target_size = target_size(1:2);
    previous_resol = [size(histo,1) size(histo,2)];    
    new_resol = round(target_size / target_sbin);
    diff = previous_resol - 2 * new_resol;
    
    Y = get_subsampling(diff(1), size(histo, 1));
    X = get_subsampling(diff(2), size(histo, 2));
    
    subhisto = histo(Y,X,:);
end

function subsampling = get_subsampling(type, maxi)
    % Type can be -1, 0 or 1
    %  0 means the previous resolution is a multiple of 2  (oxoxox)
    %  1 means that previous_resol + 1 = 2 * new_resol     (oxoxoxo)
    % -1 means that previous_resol - 1 = 2 * new_resol     (xoxoxox)
    
    if type == 0 || type == 1
        subsampling = 2:2:maxi;
    elseif type == -1
        subsampling = 1:2:maxi;
    else
        fprintf('Unexpected type: %d (should be -1, 0 or 1)\n', type);
        pause
    end        
end