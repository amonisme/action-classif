function ihisto = my_integral_histo(im, K, sbin)
% Computes the integral histogram of an image given its features.
%
% feat       the image's fetures
% sbin       size of the spatial bins

    isize = round(im.size / sbin);  
    im.feat(:,1) = round(im.feat(:,1) / sbin) + 1;   % between 1 and isize if coords are between 0 and im.size-1
    im.feat(:,2) = round(im.feat(:,2) / sbin) + 1;
    feat = sortrows(im.feat, [2 1]);
    
    ihisto = zeros([isize K]);

    k = 1;
    nfeat = size(feat,1);
    for y = 1:isize(1)
        ihisto_row = zeros([1 1 K]);
        for x = 1:isize(2)
            while k <= nfeat && feat(k,1) == x && feat(k,2) == y                
                ihisto_row(1,1,feat(k,5)) = ihisto_row(1,1,feat(k,5)) + 1;
                k = k + 1;
            end
            if y == 1
                ihisto(1,x,:) = ihisto_row;
            else
                ihisto(y,x,:) = ihisto(y-1,x,:) + ihisto_row;
            end
        end
    end
end

%     isize = round(im.size / sbin);  
%     X = round(im.feat(:,1) / sbin) + 1;   % between 1 and isize if coords are between 0 and im.size-1
%     Y = round(im.feat(:,2) / sbin) + 1;
%     T = im.feat(:,5);
%     
%     ihisto = zeros([isize K]);
% 
%     for i = 1:length(T)
%         ihisto(Y(i):end,X(i):end,T(i)) = ihisto(Y(i):end,X(i):end,T(i)) + ones(isize(1)-Y(i)+1, isize(2)-X(i)+1);
%     end
% end
