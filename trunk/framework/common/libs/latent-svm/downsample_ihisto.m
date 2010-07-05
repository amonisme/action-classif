function subhisto = downsample_ihisto(histo)
    h = size(histo, 1);
    w = size(histo, 2);
    if mod(w,2) == 0
        X = 2:2:w;
    else
        X = [2:2:w w];
    end
    if mod(h,2) == 0
        Y = 2:2:h;
    else
        Y = [2:2:h h];
    end
    subhisto = histo(X,Y,:);
end

