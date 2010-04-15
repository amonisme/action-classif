function [precision accuracy names] = build_comparator(root)
    if nargin < 1
        root = 'experiments';
    end

    names = {containers.Map(), containers.Map(), containers.Map(), containers.Map(), containers.Map()};
    
    precision = -1;
    accuracy =  -1;
    
    [perf d] = list_tests(root, 0);
    n_dir = length(d);
    
    pg = ProgressBar('Building comparator','Gathering informations...');
    for i=1:n_dir
        pg.progress(i/n_dir);
        load(fullfile(root, d{i}, 'classifier.mat'));
        [names c precision accuracy] = get_coord(classifier, names, precision, accuracy);       
        precision(mysub2ind(size(precision),(c+1))) = perf(i,1);       
        accuracy(mysub2ind(size(accuracy),(c+1))) = perf(i,2);
    end  
    pg.close();
    
    precision = precision(2:end, 2:end, 2:end, 2:end, 2:end);
    accuracy = accuracy(2:end, 2:end, 2:end, 2:end, 2:end);
    
    print_parameters_names(names);
end

function [names coord precision accuracy] = get_coord(classifier, names, precision, accuracy)
    coord = zeros(1,5);
    
    n_detectors = classifier.signature.channels.n_detector;
    detector_names = cell(n_detectors,1);    
    for i = 1:n_detectors
        detector_names{i} = classifier.signature.channels.detectors{i}.toName();
    end    
    if n_detectors == 1
        name = detector_names{1};
    else
        name = sprintf('%s%s',detector_names{1},sprintf('+%s',detector_names{2:end}));
    end
    [c precision accuracy] = get_index(names, name, 1, precision, accuracy);
    coord(1) = c;
    
    n_descriptors = classifier.signature.channels.n_descriptor;
    descriptor_names = cell(n_descriptors,1);    
    for i = 1:n_descriptors
        descriptor_names{i} = classifier.signature.channels.descriptors{i}.toName();
    end    
    if n_descriptors == 1
        name = descriptor_names{1};
    else
        name = sprintf('%s%s',descriptor_names{1},sprintf('+%s',descriptor_names{2:end}));
    end
    [c precision accuracy] = get_index(names, name, 2, precision, accuracy);
    coord(2) = c;
    
    [c precision accuracy] = get_index(names, classifier.signature.toName(), 3, precision, accuracy);
    coord(3) = c;
    
    [c precision accuracy] = get_index(names, classifier.signature.norm.toName(), 4, precision, accuracy);
    coord(4) = c; 
    
    [c precision accuracy] = get_index(names, classifier.toName(), 5, precision, accuracy);
    coord(5) = c;
end
    
function [coord precision accuracy] = get_index(map_array, name, d, precision, accuracy)
    map = map_array{d};
    if isKey(map, name)
        coord = map(name);
    else
        coord = size(map,1)+1;
        map(name) = coord;
        precision = grow_dim(d, precision);
        accuracy = grow_dim(d, accuracy);
    end
end

function stat = grow_dim(d, stat)
    s = size(stat);
    s(d) = 1;
    c = -ones(s);
    stat = cat(d,stat,c);
end