function update_tests_results(root)
    global OUPUT_LOG SHOW_BAR;
    SHOW_BAR = 1;
    OUPUT_LOG = 0;

    if nargin < 1
        root = 'experiments';
    end
    
    files = dir(root);
    directories = {files([files(:).isdir] & not(strcmp({files(:).name},'.') | strcmp({files(:).name},'..'))).name}';
    colliding = {};
    
    pg = ProgressBar('','Patching results to up-to-date format');
    for i = 1:size(directories, 1)
        pg.progress(i/size(directories, 1));
        
        classifier_file = fullfile(root,directories{i},'classifier.mat');
        results_file = fullfile(root,directories{i},'results.mat');
        accuracy_file = fullfile(root,directories{i},'accuracy.txt');
        precision_file = fullfile(root,directories{i},'precision.txt');
        
        if exist(classifier_file,'file') == 2
            files = dir(fullfile(root,directories{i}));
           
            for j = 1:size(files, 1)
                if isempty(find(strcmp(files(j).name, {'.' '..' 'classifier.mat' 'results.mat' 'log.txt' 'precision.txt' 'accuracy.txt'}), 1))
                    delete(fullfile(root,directories{i},files(j).name));
                end
            end          
            
            if exist(results_file,'file') == 2
                load(results_file);
                
                if ~exist(accuracy_file,'file')
                    accuracy = display_multiclass_accuracy(classes, confusion_table(correct_label,assigned_label));
                    fid = fopen(accuracy_file, 'w+');
                    fwrite(fid, num2str(accuracy), 'char');
                    fclose(fid);                    
                end
                
                if ~exist(precision_file,'file')
                    precision = get_precision(classes, correct_label, score); 
                    fid = fopen(precision_file, 'w+');
                    fwrite(fid, num2str(precision), 'char');
                    fclose(fid);    
                end                
            end
            
            fprintf('%s\n', classifier_file);
            load(classifier_file);
            dir_name = classifier.toFileName();
            if ~strcmp(dir_name, directories{i})
                d = fullfile(root,dir_name);
                if isdir(d)
                    colliding = {colliding{:} directories{i}};
                else
                    system(sprintf('mv "%s" "%s"', fullfile(root,directories{i}), d));
                end
                save(fullfile(d,'classifier.mat'), 'classifier');
            end
        else
            system(sprintf('rm -rf "%s"',fullfile(root,directories{i})));
        end
    end
    pg.close();
    
    if ~isempty(colliding)
        fprintf('Colliding directories:\n');
        fprintf('%s\n', colliding{:});
    end
end

