function [images map classes_name subclasses_name] = get_labeled_files(DB, msg)
    if nargin > 1
        write_log(msg);
    end
    
    if exist(DB, 'file') == 2
        [images map classes_name subclasses_name] = get_labeled_files_myformat(DB);
    else
        [images map classes_name subclasses_name] = get_labeled_files_VOC(DB);
    end
    
    global HASH_PATH;    
    HASH_PATH = num2str(get_hash_path({images(:).path}', DB));
    if nargin > 1
        write_log(sprintf('Found %d classes (%d sub-classes) (%d images)\n', length(classes_name), length(subclasses_name), length(images)));
        write_log(sprintf('Hash ID: %s\n', HASH_PATH));
        write_log('Stats:\n');
        tot = 0;
        actions = cat(1, images(:).actions);
        for i=1:length(subclasses_name)
            n_img = length(find(actions(:,i)));
            tot = tot + n_img;
            write_log(sprintf('%s: %d instances\n', subclasses_name{i}, n_img));
        end
        write_log(sprintf('------------\nTotal: %d instances\n\n', tot));
    end
end

function [images map classes_name subclasses_name] = get_labeled_files_myformat(DB)
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

    images = struct('path', cell(n_files, 1), 'actions', [], 'size', [], 'truncated', [], 'bndbox', []);
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
                images(cur_label+k-1).path = fullfile(root, classes(i).subclasses(j).path, classes(i).subclasses(j).files{k});
                images(cur_label+k-1).actions = zeros(1,n_subclasses); 
                images(cur_label+k-1).actions(sc_id) = 1; 
                [bb bb_cropped w h] = get_bb_info(images(cur_label+k-1).path);
                images(cur_label+k-1).size = [w h];
                images(cur_label+k-1).truncated = bb_cropped(1);
                images(cur_label+k-1).bndbox = bb_cropped(2:5);
            end                    
            cur_label = cur_label + n_f;
            sc_id = sc_id + 1;
        end        
    end
end

function [images map classes_name subclasses_name] = get_labeled_files_VOC(DB)
    root = fileparts(DB);
    root_VOC = fileparts(fileparts(root));
    files = dir(DB);
    
    n_classes = length(files);
    classes_name = cell(n_classes, 1);
    subclasses_name = cell(n_classes, 1);
    map = [];
    img = containers.Map;
    
    for i = 1:n_classes
        j = find(files(i).name == '_', 1) - 1;
        classes_name{i} = files(i).name(1:j);
        subclasses_name{i} = classes_name{i};
        fid = fopen(fullfile(root, files(i).name));
        ids = cell(0,3);
        while ~feof(fid)
            line = fgetl(fid);
            ids(end+1,:) = textscan(line, '%s %d %d');
        end
        fclose(fid);
        n_img = size(ids,1);
        for j = 1:size(ids,1)
            img_id = sprintf('%s@%d', ids{j,1}{1}, ids{j,2});
            if img.isKey(img_id)
                if ids{j,3} == 1
                    act = img(img_id);
                    act(i) = 1;
                    img(img_id) = act;
                end
            else
                act = zeros(1, n_classes); 
                if ids{j,3} == 1
                    act(i) = 1;
                end
                img(img_id) = act;
            end
        end
    end
    
    images = struct('path', cell(img.length(), 1), 'actions', [], 'size', [], 'truncated', [], 'bndbox', [], 'fileID', [], 'bndboxID', []);
    keys = img.keys();
    for i = 1:img.length()
        j = find(keys{i} == '@', 1);    
        img_name = keys{i}(1:(j-1));
        box_id = str2double(keys{i}((j+1):end));
        
        xml_file = fullfile(root_VOC, 'Annotations', sprintf('%s.xml', img_name));
        XML = VOCreadxml(xml_file);
        obj = XML.annotation.object;
        
        images(i).path = fullfile(root_VOC, 'JPEGImages', sprintf('%s.jpg', img_name));
        images(i).actions = img(keys{i});        
        images(i).size = [str2double(XML.annotation.size.width) str2double(XML.annotation.size.height)];
        images(i).truncated = 0;
        images(i).fileID = img_name;
        images(i).bndboxID = box_id;
        k = box_id;
        for j = 1:size(obj,2)
            if(strcmp(obj(j).name,'person'))
                k = k - 1;
                if k == 0
                    bb = obj(j).bndbox;
                    v = [str2double(bb.xmin) str2double(bb.ymin) str2double(bb.xmax) str2double(bb.ymax)];
                    images(i).bndbox = v;
                end                
            end
            if k == 0
                break;
            end
        end
        if k > 0
            fprintf('Invalid person ID %d for file %s.\n', box_id, img_name);
            keyboard;
        end
    end    
end
