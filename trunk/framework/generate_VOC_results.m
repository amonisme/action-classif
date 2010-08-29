function generate_VOC_results(input_dir, output_dir)    
    load(fullfile(input_dir, 'results.mat'));
    
    n_classes = length(classes);
    n_img = length(images);
    
    for i=1:n_classes
        file = sprintf('comp9_action_test_%s.txt', classes{i});
        fid = fopen(fullfile(output_dir, file), 'wt+');
        
        for j = 1:n_img
            fwrite(fid, sprintf('%s %d %f\n', images(j).fileID, images(j).bndboxID, score(j,i)), 'char');
        end
        
        fclose(fid);
    end
end

