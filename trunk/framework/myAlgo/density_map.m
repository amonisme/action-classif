function map = density_map(V,c)
    V = ceil((V(:,1:2) + 1) * c / 2);
    
    map = zeros(c);
    for i=1:c
        for j=1:c
            map(i,j) = length(find(V(:,1) == i & V(:,2) == j));            
        end
    end
end