function histo = get_histo_from_integral(ihisto, x1, y1, x2, y2, histo_norm)   
    x1 = x1 - 1;
    y1 = y1 - 1;    
    if x1 == 0
        if y1 == 0
            histo = ihisto(y2,x2,:);
        else
            histo = ihisto(y2,x2,:) - ihisto(y1,x2,:);
        end
    else
        if y1 == 0
            histo = ihisto(y2,x2,:) - ihisto(y2,x1,:);
        else
            histo = ihisto(y2,x2,:) + ihisto(y1,x1,:) - ihisto(y2,x1,:) - ihisto(y1,x2,:);
        end
    end
    histo = histo_norm.normalize(reshape(histo, length(histo), 1));
end

