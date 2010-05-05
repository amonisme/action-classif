function precision = evaluate(classifier, root, target)
    global OUTPUT_LOG EXPERIMENT_DIR;    

    if nargin < 2
        root = '../../DataBase/';
    end
    if nargin < 3
        target = EXPERIMENT_DIR;
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
            [cv_res cv_dev] = classifier.learn(fullfile(root, 'train'));
            save(file, 'classifier');
            save(fullfile(dir, 'cv_log.mat'), 'cv_res', 'cv_dev');  
        end
        t0 = toc;

        % Test
        file = fullfile(dir,'results.mat');
        tic;
        [Ipaths classes correct_label assigned_label score] = classifier.classify(fullfile(root, 'test'));    
        save(file,'Ipaths','classes','correct_label','assigned_label','score');
        t1 = toc;

        % Output computation time
        write_log(sprintf('Learning time: %.02fs\n', t0));
        write_log(sprintf('Classification time: %.02fs\n', t1));    
        write_log(sprintf('Total time: %.02fs\n\n', t0+t1));    
    end
    
    % Output results
    table = confusion_table(correct_label,assigned_label);  
    accuracy = display_multiclass_accuracy(classes, table);
    precision = display_precision_recall(classes, correct_label, score); 
    
    OUTPUT_LOG = 0;

    fid = fopen(fullfile(dir,'accuracy.txt'), 'w+');
    fwrite(fid, num2str(accuracy), 'char');
    fclose(fid);    
    
    fid = fopen(fullfile(dir,'precision.txt'), 'w+');
    fwrite(fid, num2str(precision), 'char');
    fclose(fid);
end

