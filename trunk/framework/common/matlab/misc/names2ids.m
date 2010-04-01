function [class_id class_name] = names2ids(labels, class_name)
    if nargin<2
        class_id = zeros(size(labels, 1),1);
        class_name = cell(size(labels, 1),1);
        
        i = [1];
        n_classes = 0;
        while(~isempty(i))
            n_classes = n_classes + 1;
            class_name{n_classes} = labels{i};
            class_id(strcmp(labels, class_name{n_classes})) = n_classes;
            i = find(class_id == 0,1);
        end
        class_name = {class_name{1:n_classes}}';
    else
        class_id = zeros(size(labels, 1),1);
        for i = 1:size(class_name, 1)
            class_id(strcmp(labels, class_name{i})) = i;
        end
    end
end
    
