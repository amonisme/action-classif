function i = mysub2ind(s, coord)
    t = zeros(size(s));
    for i=1:length(s)
        t(i) = prod(s(1:(i-1)));
    end
    i = sum((coord-1) .* t) + 1;
end