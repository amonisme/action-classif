function table = confusion_table(correct_label,assigned_label)  
    n_classes = max([correct_label; assigned_label]);        
    table = zeros(n_classes,n_classes);
    for i = 1:size(correct_label, 1)
        table(correct_label(i), assigned_label(i)) = table(correct_label(i), assigned_label(i)) + 1;
    end
end

