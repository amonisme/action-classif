function cv_ascii2bin(root, temp_dir, hash)
    [p d] = list_tests(root, 0);
    
    for i = 1:length(d)        
        fprintf('%0.1f%%: ', i*100/length(d));
        file = fullfile(root, d{i}, 'cv_log.mat');
        if exist(file, 'file') == 2 && 0
            fprintf('Loaded from cv_log.mat\n');
        else
            try
                try
                    file = fullfile(root, d{i}, 'cross_validation.txt');
                    cv_res = load(file, '-ascii');
                    file = fullfile(root, d{i}, 'cv_std_deviation.txt');
                    cv_dev = load(file, '-ascii');
                    file = fullfile(root, d{i}, 'cv_log.mat');
                    save(file, 'cv_res', 'cv_dev');
                    fprintf('Loaded text files\n');
                    file = fullfile(root, d{i}, 'cross_validation.txt');
                    delete(file);
                    file = fullfile(root, d{i}, 'cv_std_deviation.txt');
                    delete(file);                
                catch ME
                    file = fullfile(temp_dir, sprintf('%s_%s.mat', hash, d{i}));
                    load(file, 'cv_res', 'cv_dev');

                    file = fullfile(root, d{i}, 'cv_log.mat');
                    save(file, 'cv_res', 'cv_dev');
                    fprintf('Loaded binary temporary file\n');
                end              
            catch
                fprintf('Unabled to load any files: %s\n', d{i});
            end      
        end
    end
end

