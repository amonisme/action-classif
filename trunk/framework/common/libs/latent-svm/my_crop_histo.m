function histo = my_crop_histo(histo)
    histo = histo(2:(end-1), 2:(end-1), :);
end