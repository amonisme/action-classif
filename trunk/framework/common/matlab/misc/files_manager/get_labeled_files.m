function [Ipaths labels] = get_labeled_files(root, msg)
    classes = get_classes_files(root);
      
    n_classes = size(classes, 1);
    n_files = 0;
    for i=1:n_classes
        n_files = n_files + size(classes(i).files, 1);
    end

    Ipaths = cell(n_files, 1);
    labels = cell(n_files, 1);    

    cur_label = 1;
    for i=1:n_classes
        n_f = size(classes(i).files,1);
        for j=1:n_f
            Ipaths{cur_label+j-1} = fullfile(root, classes(i).name, classes(i).files(j).name);
            labels{cur_label+j-1} = classes(i).name;
        end        
        cur_label = cur_label + n_f;
    end
    
    global HASH_PATH;
    HASH_PATH = num2str(get_hash_path(Ipaths));
    if nargin > 1
        write_log(msg);
        display_classes_info(classes);
    end    
end

