function precision = evaluate(classifier, root, db_name, target, sets_names)
    global OUTPUT_LOG EXPERIMENT_DIR;    

    if nargin < 4
        target = EXPERIMENT_DIR;
    end
    if nargin < 5
        sets_names = {'train' 'test'};
    end
    
    force_recompute = 0;

    EXPERIMENT_DIR = target;    
    path_classifier = classifier.toFileName();    
    dir = fullfile(EXPERIMENT_DIR,path_classifier);
    [status,message,messageid] = mkdir(EXPERIMENT_DIR);
    [status,message,messageid] = mkdir(dir);
        
    file = fullfile(dir,'results.mat');
    
    if exist(file,'file') == 2 && ~force_recompute
        OUTPUT_LOG = 0;
        load(file);
        fprintf('Results loaded from %s.\n', file);
    else
        % Init LOG file
        OUTPUT_LOG = 1;
        write_log(sprintf('Log file for %s\n\n%s\n', path_classifier, classifier.toString()), fullfile(dir,'log.txt')); 

        % Train
        file = fullfile(dir,'classifier.mat');
        tic;
        if exist(file,'file') == 2 && ~force_recompute
            load(file);
            write_log(sprintf('Classifier loaded from file %s\n',file)); 
        else
            [cv_prec cv_dev_prec cv_acc cv_dev_acc] = classifier.learn(make_DB_name(root, db_name, sets_names{1}));
            save(file, 'classifier');
            save(fullfile(dir, 'cv_log.mat'), 'cv_prec', 'cv_dev_prec', 'cv_acc', 'cv_dev_acc');  
        end
        t0 = toc;

        % Test
        file = fullfile(dir,'results.mat');
        tic;
        [images classes subclasses map_sub2sup assigned_action score] = classifier.classify(make_DB_name(root, db_name, sets_names{2}));    
        save(file,'images','classes','subclasses','map_sub2sup','assigned_action','score');
        t1 = toc;

        % Output computation time
        write_log(sprintf('Learning time: %.02fs\n', t0));
        write_log(sprintf('Classification time: %.02fs\n', t1));    
        write_log(sprintf('Total time: %.02fs\n\n', t0+t1));    
    end
    
    % Output results
    has_subclass = ~isempty(map_sub2sup) && ~isempty(find(map_sub2sup - (1:length(map_sub2sup))'));
    if has_subclass     
        fprintf('Results for subclasses:\n');    
    end
    correct_labels = cat(1, images(:).actions);
    table = confusion_table(correct_labels,assigned_action);  
    accuracy = display_multiclass_accuracy(subclasses, table);
    precision = display_precision_recall(subclasses, correct_labels, score); 
    
    if has_subclass
        fprintf('Results for classes:\n');
        [new_score new_correct_action new_assigned_action] = convert2supclasses(map_sub2sup, score, correct_labels, assigned_action);
        new_table = confusion_table(new_correct_action, new_assigned_action);  
        accuracy = display_multiclass_accuracy(classes, new_table);
        precision = display_precision_recall(classes, new_correct_action, new_score); 
    end
    
    OUTPUT_LOG = 0;

    fid = fopen(fullfile(dir,'accuracy.txt'), 'w+');
    fwrite(fid, num2str(accuracy), 'char');
    fclose(fid);    
    
    fid = fopen(fullfile(dir,'precision.txt'), 'w+');
    fwrite(fid, num2str(precision), 'char');
    fclose(fid);
end

