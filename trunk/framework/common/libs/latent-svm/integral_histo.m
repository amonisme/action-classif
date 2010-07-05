function ihisto = integral_histo(im, K, sbin)
% Computes the integral histogram of an image given its features.
%
% feat       the image's fetures
% sbin       size of the spatial bins

    isize = ceil(im.size / sbin);
    X = ceil(im.feat(:,1) / sbin);
    Y = ceil(im.feat(:,2) / sbin);

    ihisto = zeros([isize K]);

    ihisto(1,1,:) = add_to_histo(zeros(K,1), im.feat(X == 1 & Y == 1, 5));
    
    for x = 2:isize(2)
        ihisto(1,x,:) = add_to_histo(ihisto(1,x-1,:), im.feat(X == x & Y == 1, 5));
    end
    
    for y = 2:isize(1)
        line = zeros(1,1,K);        
        for x = 1:isize(2)
            line = add_to_histo(line, im.feat(X == x & Y == y, 5));
            ihisto(y,x,:) = line + ihisto(y-1,x,:);
        end
    end
end


function histo = add_to_histo(histo, types)
    for i=1:length(types)
        histo(types(i)) = histo(types(i)) + 1;
    end
end
