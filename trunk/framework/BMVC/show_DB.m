classdef show_DB < handle
    
    properties (SetAccess = protected)
        db_root
        width     % total width
        height    % height for a class
        margin    % margin between images
        
        img_width
        img_path
        subset
    end
    
    methods
        function obj = show_DB(root, width, height, margin)
            classes = get_classes_files(root);
            n_classes = length(classes);
            
            obj.width = width;
            obj.height = height;
            obj.img_width = cell(n_classes, 1);
            obj.img_path = cell(n_classes, 1);
            for i = 1:n_classes
                n_files = length(classes(i).files);
                obj.img_width{i} = zeros(n_files,1);
                obj.img_path{i} = cell(n_files, 1);
                for j = 1:n_files
                    obj.img_path{i}{j} = fullfile(classes(i).path, classes(i).files(j).name);
                    info = imfinfo(obj.img_path{i}{j});
                    obj.img_width{i}(j) = floor(info.Width/info.Height*height);
                end
            end
            
            obj.generate(margin);
        end
        
        function obj = generate(obj, margin)
            obj.margin = margin;
            n_classes = length(obj.img_width);
            
            obj.subset = cell(n_classes,1);
            for i = 1:n_classes
                obj.generate_class(i);
            end            
        end
        
        function obj = generate_class(obj, n)
            min_rest = +Inf;
            
            for i = 1:100        
                curr_subset = [];
                w = 0;
                p = randperm(length(obj.img_width{n}));
                while ~isempty(p)
                    if w+obj.img_width{n}(p(1)) <= obj.width
                        w = w + obj.img_width{n}(p(1)) + obj.margin;
                        curr_subset = [curr_subset p(1)];
                    end
                    p = p(2:end);
                end
                rest = obj.width - (w - obj.margin);                 
                if rest < min_rest
                    min_rest= rest;
                    obj.subset{n} = curr_subset;
                end
            end            
        end
        
        function generate_picture(obj, file)
            n_classes = length(obj.img_width);
            img = zeros(obj.height + obj.margin*(n_classes-1), obj.width, 3);
            y = 1;
            for i = 1:n_classes
                x = 1;
                for j = 1:length(obj.subset{i})
                    k = obj.subset{i}(j);
                    w = obj.img_width{i}(k);
                    I = imread(obj.img_path{i}{k});            
                    I = imresize(I, [obj.height w]);
                    I = double(I)/255;                       
                    img(y:(y+obj.height-1), x:(x+w-1), :) = I;            
                    x = x + w + obj.margin;
                end
                y = y + obj.height + obj.margin;
            end

            imwrite(img, file, 'png');
        end
    end
end    