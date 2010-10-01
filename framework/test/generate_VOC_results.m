function generate_VOC_results(input_dir, output_dir)    
    load(fullfile(input_dir, 'results.mat'));
    
    n_classes = length(classes);
    n_img = length(images);
    
    if ~isdir(output_dir)
        mkdir(output_dir);
    end
    
    for i=1:n_classes
        file = fullfile(output_dir,sprintf('comp9_action_test_%s.txt', classes{i}));
        fid = fopen(file, 'wt+');
        
        for j = 1:n_img
            if isinf(score(j,i))
                if score(j,i) > 0
                    sc = 1000;
                else
                    sc = -1000;
                end
            else
                sc = score(j,i);
            end
            fwrite(fid, sprintf('%s %d %f\n', images(j).fileID, images(j).bndboxID, sc), 'char');
        end
        
        fclose(fid);
    end
end

