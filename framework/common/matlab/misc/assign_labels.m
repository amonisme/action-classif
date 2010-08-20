function assigned_label = assign_labels(scores)
    n_img = size(scores,1);
    assigned_label = zeros(n_img,1); 
    for i = 1:n_img
        [m, j] = max(scores(i,:));
        assigned_label(i) = j;
    end
end