function [Ipaths ids map classes_name subclasses_name] = get_labeled_files(DB, msg)
    classes = get_classes_files(DB);
    root = fileparts(DB);
    
    n_classes = length(classes);
    n_files = 0;
    n_subclasses = 0;

    [n, I] = sort({classes(:).name});   
    classes = classes(I);
       
    for i=1:n_classes
        [n, I] = sort({classes(i).subclasses(:).name});
        classes(i).subclasses = classes(i).subclasses(I);   
        for j=1:length(classes(i).subclasses)
            n_files = n_files + length(classes(i).subclasses(j).files);            
            n_subclasses = n_subclasses + 1;
        end
    end

    Ipaths = cell(n_files, 1);
    ids = zeros(n_files, 1);
    classes_name = cell(n_classes, 1);
    subclasses_name = cell(n_subclasses, 1);
    map = zeros(n_subclasses, 1);

    cur_label = 1;
    sc_id = 1;
    for i=1:n_classes
        classes_name{i} = classes(i).name;
        n_sub = length(classes(i).subclasses);
        for j=1:n_sub;
            if n_sub == 1
                subclasses_name{sc_id} = classes(i).name;
            else
                subclasses_name{sc_id} = sprintf('%s-%s', classes(i).name, classes(i).subclasses(j).name);
            end                        
            map(sc_id) = i;
            n_f = size(classes(i).subclasses(j).files,1);
            for k=1:n_f
                Ipaths{cur_label+k-1} = fullfile(root, classes(i).subclasses(j).path, classes(i).subclasses(j).files{k});
                ids(cur_label+k-1) = sc_id;                
            end                    
            cur_label = cur_label + n_f;
            sc_id = sc_id + 1;
        end
        
    end
    
    global HASH_PATH;
    HASH_PATH = num2str(get_hash_path(Ipaths, DB));
    if nargin > 1
        write_log(msg);
        display_classes_info(classes);
    end    
end

