function [repart_init repart_scaled scaled]   = analyse_size(dim, step, h_target)
    M = max(dim, [], 1);
    repart_init = zeros(ceil(M(1)/step(1)), ceil(M(2)/step(2)));
    
    for i=1:size(dim,1)
        h = dim(i,1);
        w = dim(i,2);
        repart_init(ceil(h/step(1)), ceil(w/step(2))) = repart_init(ceil(h/step(1)), ceil(w/step(2)))+1;
    end
    
    hw_mean = mean(dim, 1);
    hw_median= median(dim, 1);
    
    sd = dim - repmat(hw_mean,size(dim,1),1);
    sd = sqrt(mean(sd.*sd, 1));
    
    fprintf('Before correction:\n');
    fprintf('Mean size: w = %.2f, h = %.2f\n', hw_mean(2), hw_mean(1));
    fprintf('Median size: w = %.2f, h = %.2f\n', hw_median(2), hw_median(1));
    fprintf('Standard deviation: w = %.2f, h = %.2f\n', sd(2), sd(1));
    
    scale = h_target./dim(:,1);
    scaled = dim .* [scale scale];
    
    M = max(scaled, [], 1);
    repart_scaled = zeros(ceil(M(1)/step(1)), ceil(M(2)/step(2)));
    
    for i=1:size(scaled,1)
        h = scaled(i,1);
        w = scaled(i,2);
        repart_scaled(ceil(h/step(1)), ceil(w/step(2))) = repart_scaled(ceil(h/step(1)), ceil(w/step(2)))+1;
    end
    
    hw_mean = mean(scaled, 1);
    hw_median= median(scaled, 1);
    
    sd = scaled - repmat(hw_mean,size(scaled,1),1);
    sd = sqrt(mean(sd.*sd, 1));
    
    fprintf('After correction:\n');
    fprintf('Mean size: w = %.2f, h = %.2f\n', hw_mean(2), hw_mean(1));
    fprintf('Median size: w = %.2f, h = %.2f\n', hw_median(2), hw_median(1));
    fprintf('Standard deviation: w = %.2f, h = %.2f\n', sd(2), sd(1));
end

