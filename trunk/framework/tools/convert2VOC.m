function convert2VOC(path_Annot_JPG, path_sets, path_output)
% path_Annot_JPG: path to the directory containing the directories
% 'Annotations' and 'JPEGImages'
% path_sets: path to the directory containing the directories named as the
% actions. Those directories should contain a copy of the training images
% of the class
% path_output: path where a DB with the VOC format will be produced

    DB_NAME = 'Willow-actions';

    ann_src = fullfile(path_Annot_JPG, 'Annotations');
    img_src = fullfile(path_Annot_JPG, 'JPEGImages');
    
    files = dir(img_src);
    files = files(~cat(1,files(:).isdir));
    
    action_names = {};
    actions = zeros(0,1);
    obj_ref = struct('filename', {}, 'fileID', {}, 'bndboxID', {});
    fileMap = containers.Map();
    img2inst = containers.Map(0,[1 2]);
    
    output_ann = struct('annotation', {});
    
    fprintf('Scanning input DB...\n');
    n_img = size(files,1);
    for i=1:n_img
        j = strfind(files(i).name,'.');           
        filename = files(i).name(1:(j(1)-1));
        XML = VOCreadxml(fullfile(ann_src, sprintf('%s.xml', filename)));

        ann = XML.annotation;
        output_ann(end+1).annotation = struct( 'filename', ann.filename, ...
                                               'originalfile', ann.originalfile, ...
                                               'folder', DB_NAME, ...
                                               'source', struct('annotation', DB_NAME, ...
                                                                'database', DB_NAME, ...
                                                                'image', ann.source.image, ...
                                                                'flickrid', ann.source.flickrid), ...
                                               'segmented', ann.segmented, ...
                                               'size', ann.size, ...
                                               'object', struct('name', {}, 'bndbox', {}, 'pose', {}, 'difficult', {}, 'truncated', {}));
        oann = output_ann(end).annotation;
        fileMap(files(i).name) = i;

        if(isfield(ann,'object'))
            obj = ann.object;    
            person_count = 0;
            for j=1:size(obj,2)
                oann.object(end+1).name = obj(j).name;
                oann.object(end).bndbox = obj(j).bndbox;
                oann.object(end).pose = obj(j).pose;
                oann.object(end).difficult = obj(j).difficult;
                oann.object(end).truncated = obj(j).truncated;
                if(isfield(ann,'occluded'))
                    oann.object(end).occluded = obj(j).occluded;
                end                        
                if(strcmp(obj(j).name,'person'))
                    person_count = person_count + 1;
                    obj_ref(end+1).filename = filename;
                    obj_ref(end).fileID = i;
                    obj_ref(end).bndboxID = person_count;   % FIXME: check if it should indicate the rank of the bndbox over all the bndboxes (including objects) or of persons only.
                    if img2inst.isKey(i)
                        img2inst(i) = [img2inst(i); length(obj_ref)];
                    else
                        img2inst(i) = length(obj_ref);
                    end
                    actions = [actions; zeros(1,size(actions,2))];

                    if(isfield(obj(j),'action') &&  ~isempty(obj(j).action))
                       for k=1:length(obj(j).action)
                            node_act = obj(j).action(k);                                
                            if(isfield(node_act,'ambiguous') && str2double(node_act.ambiguous))
                                continue;
                            end

                            n = 0;
                            for m=1:length(action_names)
                                if(strcmp(action_names{m},node_act.actionname))
                                    n = m;
                                    break;
                                end
                            end
                            if(n == 0)
                                action_names{end+1} = node_act.actionname;                                    
                                actions = [actions zeros(size(actions,1),1)];
                                n = length(action_names);
                            end
                            actions(end, n) = 1;
                       end
                   end
                end
            end
        end
    end
    
    n_actions = length(action_names);
    
    fileIDs = cat(1, obj_ref(:).fileID);
    fprintf('\nFound %d classes:\n', n_actions);
    for i=1:n_actions
        fIDs = fileIDs(logical(actions(:,i)));
        fprintf('%s: %d instances (%d files)\n', action_names{i}, length(find(actions(:,i))), length(unique(fIDs)));        
    end    
    
    failed = 0;
    train_set = struct('n_inst', cell(n_actions, 1), 'n_img', cell(n_actions, 1), 'set', []);
    test_set = struct('n_inst', cell(n_actions, 1), 'n_img', cell(n_actions, 1), 'set', []);    
    fprintf('\nScanning sets...\n');
    for i=1:n_actions
        set_dir = fullfile(path_sets,action_names{i});
        fprintf('Cheking ''%s''...  ', action_names{i});
        if(exist(set_dir, 'dir') == 0)
            failed = 1;
            fprintf('FAILED (directory not found)\n');
            break;
        end
        
        train_set(i).n_inst = 0;
        train_set(i).n_img = 0;
        train_files = dir(set_dir);
        is_dir = cat(1, train_files(:).isdir);
        train_files = train_files(logical(~is_dir));        
        is_train_img = zeros(n_img, 1);
        for j = 1:length(train_files)
            if fileMap.isKey(train_files(j).name);
                k = fileMap(train_files(j).name);
                is_train_img(k) = 1;                             
                I = (fileIDs == k);
                train_set(i).n_img = train_set(i).n_img + 1;                
                train_set(i).n_inst = train_set(i).n_inst + length(find(actions(I,i)));                
            else
                failed = 1;
                fprintf('FAILED (image unknown: %s)\n', train_files(j).name);
                break;                
            end
        end
        if failed
            break;
        end  
        train_set(i).set = find(is_train_img == 1);        
        fIDs = fileIDs(logical(actions(:,i)));
        test_set(i).n_inst = length(find(actions(:,i))) - train_set(i).n_inst;
        test_set(i).n_img = length(unique(fIDs)) - train_set(i).n_img;
        test_set(i).set = intersect(find(is_train_img == 0), unique(cat(1,obj_ref(logical(actions(:,i))).fileID)));
        fprintf('OK\n');
    end
    
    fprintf('Checking consistency... ');
    for i=1:n_actions
        for j=1:n_actions
            I = intersect(train_set(i).set, test_set(j).set)';
            if ~isempty(I)
                if ~failed
                    fprintf('FAILED\n');
                    failed = 1;
                end
                for k = I
                    fprintf('Training image %s for class %s appears in testing set for class %s.\n', files(k).name, action_names{i}, action_names{j});
                end
            end            
        end
    end
    
    full_train_set = zeros(size(actions, 1), 1);
    full_test_set  = zeros(size(actions, 1), 1);
    for i = 1:n_actions
        for j = 1:length(train_set(i).set)
            full_train_set(img2inst(train_set(i).set(j))) = 1;            
        end
        for j = 1:length(test_set(i).set)
            full_test_set(img2inst(test_set(i).set(j))) = 1;            
        end
    end
    full_train_set = logical(full_train_set);
    full_test_set = logical(full_test_set);
    
    if ~failed
        fprintf('OK\n\nTraining set:\n');
        for i=1:n_actions
            fprintf('%s: %d instances (%d files)\n', action_names{i}, train_set(i).n_inst, train_set(i).n_img);        
        end
    
        fprintf('\nTesting set:\n');
        for i=1:n_actions
            fprintf('%s: %d instances (%d files)\n', action_names{i}, test_set(i).n_inst, test_set(i).n_img);        
        end            
   
        if nargin == 3
            fprintf('\nGenerating DB:\n');
            if(exist(path_output,'dir') == 0)
                mkdir(path_output);
            end
            current_dir = cd;
            cd(path_output);
            system('mkdir JPEGImages');
            system('mkdir Annotations');
            for i = 1:length(output_ann)
                file = output_ann(i).annotation.filename;
                j = strfind(file,'.');
                extfree_file = file(1:(j(1)-1));

                fprintf('Processing %s...\n', extfree_file);                
                system(sprintf('cp %s %s', fullfile(img_src, file), fullfile('JPEGImages', file)));
                VOCwritexml(output_ann(i), fullfile('Annotations', sprintf('%s.xml', extfree_file)));
            end
            system('mkdir ImageSets');
            system('mkdir ImageSets/Action'); 
            cd('ImageSets/Action');
            for i=1:n_actions
                write_set(sprintf('%s_train.txt', action_names{i}), obj_ref(full_train_set), actions(full_train_set, i));
                write_set(sprintf('%s_test.txt', action_names{i}),  obj_ref(full_test_set),  actions(full_test_set, i));
            end
            cd(current_dir);
        end
    end
end

function write_set(file, obj_ref, action)   
    action(action == 0) = -1;
    
    fid = fopen(file, 'w');
    for i=1:length(obj_ref)
        out = sprintf('%s %d %d\n', obj_ref(i).filename, obj_ref(i).bndboxID, action(i));
        fwrite(fid, out, 'char');
    end
    fclose(fid);
end