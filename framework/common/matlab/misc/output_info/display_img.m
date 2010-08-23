function display_img(N, dir, prefix, root, is_LSVM)
    if nargin < 3
            prefix = '';
    end
    if nargin < 4
        root = 'experiments';
    end
    if nargin < 5
        is_LSVM = 0;
    end
    

    load(fullfile(root,dir,'classifier.mat'));   
    load(fullfile(root,dir,'results.mat'));    
    n_classes = size(classes, 1);
   
    f = figure;
    
    if isempty(prefix)
        file = 'results.tex';
    else
        file = sprintf('%s.tex', prefix);
    end

    if ~isdir('experiments');
        mkdir('experiments');
    end
    
    fid = fopen(fullfile('experiments', file), 'w+');
    fprintf(fid, '\\documentclass[10pt,a4paper]{article}\n\\usepackage{graphicx}\n\\usepackage{float}\n\\usepackage[tight,footnotesize]{subfigure}\n\n\\title{%s}\n\n\\begin{document}\n\n\\maketitle\n\n', regexprep(classifier.toFileName(),'_', '\\_'));
           
    fprintf(fid, regexprep(classifier.toString(),'\n', '\\\\\\\\\n'));
    
    correct_label = cat(1, images(:).actions);
    
    for i=1:n_classes
        
        fprintf(fid, '\\section{%s}\n', classes{i});  
        
        % if LSVM, print the model
        if is_LSVM
            f2 = figure;
            visualizemodel(classifier.models{i});
            model_file = sprintf('%s%s_model.png', prefix, classes{i});
            print('-dpng', fullfile('experiments', model_file));
            fprintf(fid,'\\begin{center}\n\\includegraphics[width=13cm]{%s}\n\\end{center}\n\n', model_file);
            close(f2);
        end
        
        % Compute PR
        [rec,prec,ap,sortind] = precisionrecall(score(:, i), correct_label(:,i));
        ap = ap*100;
        Ipath = {images(sortind).path}';
        correct = correct_label(sortind,i);
        assigned = assigned_action(sortind,i);
        sc = score(sortind, i);

        % plot precision/recall
        name = sprintf('Action ''%s''',classes{i});
        
        plot(rec,prec,'-');
        grid;
        xlabel 'recall'
        ylabel 'precision'

        title(sprintf('%s - AP = %.3f',name, ap));
        axis([0 1 0 1]);

        pr_file = sprintf('%s%s.png', prefix, classes{i});
        print('-dpng', fullfile('experiments', pr_file));
        
        fprintf(fid,'\\begin{center}\n\\includegraphics[height=8cm]{%s}\n\\end{center}\n\n', pr_file);
        
        
        % Correctly classified images, highest score
        I = find(assigned == i & correct == i);
        n = min(length(I), N);
        n
        fprintf(fid,'\\begin{figure}[H]\n\\centering\n');
        for j = 1:n
            if is_LSVM
                path = lsvm_draw_boxes(classifier, Ipath{I(j)}, prefix, classes{i}, 'correct_high', j);
            else
                path = Ipath{I(j)};
            end
            fprintf(fid,'\\subfigure[%.2f]{\\includegraphics[height=3cm]{%s}}\n', sc(I(j)), path);
        end
        fprintf(fid,'\\caption{%s: Correctly classified images, highest score}\n\\end{figure}\n', classes{i});
        
        % Correctly classified images, smallest score
        fprintf(fid,'\\begin{figure}[H]\n\\centering\n');
        for j = n:-1:1
            if is_LSVM
                path = lsvm_draw_boxes(classifier, Ipath{I(end-j+1)}, prefix, classes{i}, 'correct_low', j);
            else
                path = Ipath{I(end-j+1)};
            end            
            fprintf(fid,'\\subfigure[%.2f]{\\includegraphics[height=3cm]{%s}}\n', sc(I(end-j+1)), path);
        end
        fprintf(fid,'\\caption{%s: Correctly classified images, smallest score}\n\\end{figure}\n', classes{i});
        
        % Misclassified images, highest score
        I = find(assigned == i & correct ~= i, N);
        fprintf(fid,'\\begin{figure}[H]\n\\centering\n');
        for j = 1:length(I)
            if is_LSVM
                path = lsvm_draw_boxes(classifier, Ipath{I(j)}, prefix, classes{i}, 'incorrect_high', j);
            else
                path = Ipath{I(j)};
            end               
            fprintf(fid,'\\subfigure[%.2f]{\\includegraphics[height=3cm]{%s}}\n', sc(I(j)), path);                    
        end
        fprintf(fid,'\\caption{%s: Misclassified images, highest score}\n\\end{figure}\n\\newpage', classes{i});
    end
    
    fprintf(fid, '\n\\end{document}');
    fclose(fid);
     
    close(f);
    
    cd 'experiments';
    system(sprintf('pdflatex %s', file));
    
    if isempty(prefix)
        file = 'results.pdf';
    else
        file = sprintf('%s.pdf', prefix);
    end
    
    system(sprintf('evince %s &', file));
    cd '..';
end


function path = lsvm_draw_boxes(classifier, img, prefix, class, type, i)
    boxes = classifier.classify_and_get_boxes(img);
    img = draw_boxes_on_img(img, boxes,3);
    file = sprintf('%s%s_%s_%d.png', prefix, class, type, i);
    path = fullfile('experiments', file);
    imwrite(img, path, 'png');
end

function img = draw_boxes_on_img(img, boxes, width)
    img = imread(img);
    
    c = boxes(end-1);
    boxes = boxes(1:(end-2));
    n_boxes = length(boxes) / 4;
    boxes = reshape(boxes, 4, n_boxes)';
    
    colors = [255   0   0; ...
                0 255   0;
                0   0 255];
    
    for i=2:n_boxes
        [img dx dy] = draw_box_on_img(img, boxes(i,:), colors(end,:), width);
        boxes(:,[1 3]) = boxes(:,[1 3]) + dx;
        boxes(:,[2 4]) = boxes(:,[2 4]) + dy;
    end
    
    img = draw_box_on_img(img, boxes(1,:), colors(mod(c,size(colors,1)-1)+1,:), width);
end

function [img dx dy] = draw_box_on_img(img, box, c, width)
    box = floor(box);
    [h w d] = size(img);
    dx = 0;
    dy = 0;

    d = max(box([1 3])) - w;
    if d > 0
        img = [img (255*ones(h,d,3))];
        w = w + d;
    end
    d = max(box([2 4])) - h;
    if d > 0
        img = [img; (255*ones(d,w,3))];
        h = h + d;
    end    
    d = 1 - min(box([1 3]));
    if d > 0
        img = [(255*ones(h,d,3)) img];
        dx = d;
        w = w + d;
    end
    d = 1 - min(box([2 4]));
    if d > 0
        img = [(255*ones(d,w,3)); img];
        dy = d;
    end   
    box = box + [dx dy dx dy];
    [img dy1] = draw_H_line(img, box(2), box(1), box(3), c, width);
    box = box + [0 dy1 0 dy1];
    [img dy2] = draw_H_line(img, box(4), box(1), box(3), c, width);   
    box = box + [0 dy2 0 dy2];
    [img dx1] = draw_V_line(img, box(1), box(2), box(4), c, width);   
    box = box + [dx 0 dx1 0];
    [img dx2] = draw_V_line(img, box(3), box(2), box(4), c, width);  
    dx = dx + dx1 + dx2;
    dy = dy + dy1 + dy2;
end

function [img dy] = draw_H_line(img, y, x1, x2, c, width)
    [h w d] = size(img);
    dy = ceil(width/2 - (1:width));
    minY = min(dy);
    maxY = max(dy);
    y = y + dy;
    
    dy = 0;
    d = max(y) - h;
    if d > 0
        img = [img; (255*ones(d,w,3))];
    end 
    d = 1 - min(y);
    if d > 0
        img = [(255*ones(d,w,3)); img];
        y = y + d;
        dy = d;
    end
    
    x3 = max(min([x1 x2]+minY),1);
    x4 = min(max([x1 x2]+maxY),w);

    for i = 1:length(y)
        for x = x3:x4
            img(y(i), x, :) = c;
        end
    end
end

function [img dx] = draw_V_line(img, x, y1, y2, c, width)
    [h w d] = size(img);
    dx = ceil(width/2 - (1:width));
    minX = min(dx);
    maxX = max(dx);
    x = x + dx;
    
    dx = 0;
    d = max(x) - w;
    if d > 0
        img = [img (255*ones(h,d,3))];
    end 
    d = 1 - min(x);
    if d > 0
        img = [(255*ones(h,d,3)) img];
        x = x + d;
        dx = d;
    end
    
    y3 = max(min([y1 y2]+minX),1);
    y4 = min(max([y1 y2]+maxX),h);
    
    for i = 1:length(x)
        for y = y3:y4
            img(y, x(i), :) = c;
        end
    end
end
