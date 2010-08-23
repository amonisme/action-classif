function new = convert_old_label(old, n_classes)
    new = zeros(size(old,1), n_classes);
    
    for i=1:n_classes
        new(old == i,i) = 1;
    end
end

