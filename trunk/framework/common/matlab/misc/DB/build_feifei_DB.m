function build_feifei_DB()
    classes_names = {'bassoon' 'erhu' 'flute' 'frenchhorn' 'guitar' 'saxophone' 'violin'};
    traintest = {'train' 'test'};
 
    classes = struct('name', classes_names, 'subclasses', struct('name', {'play' 'with'}, 'path', []));
    for i = 1:2
        for j=1:7
            classes(j).subclasses(1).path = sprintf('play_instrument/%s/%s', classes_names{j}, traintest{i});
            classes(j).subclasses(2).path = sprintf('with_instrument/%s/%s', classes_names{j}, traintest{i});
        end
        file = sprintf('feifei_multi.%s.mat', traintest{i});
        save(file, 'classes');
    end
        
    for j=1:7
        pos = sprintf('%s+', classes_names{j});
        neg = sprintf('%s-', classes_names{j});
        classes = struct('name', {pos neg}, 'subclasses', struct('name', '', 'path', []));
        for i= 1:2
            classes(1).subclasses.path = sprintf('play_instrument/%s/%s', classes_names{j}, traintest{i});
            classes(2).subclasses.path = sprintf('with_instrument/%s/%s', classes_names{j}, traintest{i});
            file = sprintf('feifei_%s.%s.mat', classes_names{j}, traintest{i});
            save(file, 'classes');
        end
    end    
end

