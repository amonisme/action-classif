function display_img_html(dir, target_dir, prefix, is_LSVM)
    %target_dir = '/data/public_html/vdelaitr/html_summary';
    %target_dir = 'VOC_results/html';
    img_per_line = 6;
    img_size = 150;
    
    if ~isdir(target_dir)
        mkdir(target_dir);
    end
    target_dir = fullfile(target_dir, prefix);
    if ~isdir(target_dir)
        mkdir(target_dir);
    end
    
    if nargin < 3
        is_LSVM = 0;
    end
    
    load(fullfile(dir,'classifier.mat'));   
    load(fullfile(dir,'results.mat'));    
    if exist('subclasses', 'var') ~= 1
        n_classes = size(classes, 1);
    else
        n_classes = size(subclasses, 1);
        classes = subclasses;
    end    
          
    file = 'index.html';    
    fid = fopen(fullfile(target_dir, file), 'w+');
    fprintf(fid, '<html>\n<body>\n<h1>%s<h1>\n', classifier.toFileName());    
    
    % Confusion table:
    correct_label = cat(1, images(:).actions);
    table = confusion_table(correct_label,assigned_action);     
    [perf_total perf_classes table] = get_accuracy(table);

    fprintf(fid, '<h2>Confusion Table (Accuracy = %0.2f)</h2>\n<table align="center" border="1">', perf_total);
 
    fprintf(fid, '<tr><td></td>\n');
    for j=1:n_classes
        fprintf(fid, '<td align="center">%d</td>', j);
    end
    fprintf(fid, '</tr>\n');
    
    for i=1:n_classes
        fprintf(fid, '<tr><td>%d - %s</td>\n', i, classes{i});
        for j=1:n_classes
            bgcolor = sprintf('%02X', ceil(2.55 * table(i,j)));            
            bgcolor = [bgcolor bgcolor bgcolor]; % gray
            limit = 30;
            if table(i,j) >= limit
                color = '#000000';
            else
                color = sprintf('%02X', ceil(255 * table(i,j)/limit));            
                color = [color color color]; % gray
            end
            fprintf(fid, '<td bgcolor="#%s"><font color="%s">%.2f</font></td>', bgcolor, color, table(i,j));
        end
        fprintf(fid, '</tr>\n');
    end
    fprintf(fid, '</table>\n');

    % MAP
    precision = size(n_classes, 1);    
    for i=1:n_classes
        [rec,prec,ap] = precisionrecall(score(:, i), correct_label(:,i));
        precision(i) = ap*100;
    end
    fprintf(fid, '<h2>Average precision (mAP = %0.2f)</h2>\n', mean(precision));
    
    fprintf(fid, '<table align="center" border="0" width="80%%"><tr>\n');
    for i=1:n_classes
        fprintf(fid, '<td>%s:&nbsp&nbsp</td><td align="center">%0.2f</td><td>', classes{i}, precision(i));
        generate_img(fid, sprintf('%s_pr.png', classes{i}), 'width="500"');
        fprintf(fid, '</td>\n');
        
        if mod(i,2) == 1
            fprintf(fid, '<td width="100%%"></td>\n');
        end
        if i==n_classes || mod(i,2) == 0
            fprintf(fid, '</tr><tr>\n');
        end
    end    
    fprintf(fid, '</table>\n');
    
    
    % Links
    fprintf(fid, '<h2>Details</h2>\n');
    for i=1:n_classes
      fprintf(fid, '<font size="3"><a href="%s.html">%s</a><br></font>\n', classes{i}, classes{i});        
    end
    fprintf(fid, '</body>\n</html>');
    fclose(fid);    
           
    for i=1:n_classes
        file = sprintf('%s.html', classes{i});
        fid = fopen(fullfile(target_dir, file), 'w+');
        fprintf(fid, '<html>\n<body>\n');        
        fprintf(fid, '<h1>%s</h1>\n', classes{i});  
        fprintf(fid, '<font size="3"><a href="index.html">Back to index</a><br></font>\n');        
        
        % if LSVM, print the model
        if is_LSVM
            model_file = sprintf('%s_model.png', classes{i});

%             f = figure;
%             visualizemodel(classifier.models{i});
%             print('-dpng', fullfile(target_dir, model_file));
%             close(f);

            fprintf(fid,'<h2>Model</h2>\n<center>\n');
            generate_img(fid, model_file, 'height="400"');
            fprintf(fid, '\n</center><br><font size="3"><a href="index.html">Back to index</a><br></font>\n');        
        end
        
        % Compute PR
        [rec,prec,ap,sortind] = precisionrecall(score(:, i), correct_label(:,i));
        ap = ap*100;
        Ipaths = {images(sortind).path}';        
        correct = correct_label(sortind,i);
        assigned = assigned_action(sortind,i);
        sc = score(sortind, i);

        % plot precision/recall
        pr_file = sprintf('%s_pr.png', classes{i});

%         f = figure;
%         name = sprintf('Action ''%s''',classes{i});
%         
%         plot(rec,prec,'-');
%         grid;
%         xlabel 'recall'
%         ylabel 'precision'
% 
%         title(sprintf('%s - AP = %.3f',name, ap));
%         axis([0 1 0 1]);
% 
%         print('-dpng', fullfile(target_dir, pr_file));
%         close(f);
%         

        fprintf(fid,'<h2>Precision Recall</h2>\n<center>\n');
        generate_img(fid, pr_file, 'height="400"');
        fprintf(fid, '\n</center><br><font size="3"><a href="index.html">Back to index</a><br></font>\n');        
        
        % Images of the class
        fprintf(fid,'<h2>Images sorted by decreasing AP\n</h2>', classes{i});
        generate_imgtab(fid, target_dir, classifier, classes, Ipaths, assigned, sc, i, correct, img_per_line, img_size, is_LSVM);
                
        fprintf(fid, '</body>\n</html>');
        fclose(fid);
    end    
end

function generate_imgtab(fid, target_dir, classifier, classes, Ipaths, assigned_label, score, i, correct_label, img_per_line, img_size, is_LSVM)
    fprintf(fid,'<table border="0" align="center"><tr>'); 
    deb_line = 1;
    num_img = length(Ipaths);
    for j = 1:num_img
        if 0
            if is_LSVM
                path = lsvm_draw_boxes(target_dir, classifier, assigned_label(j), Ipaths{j}, classes{i}, type, j);
            else
                path = sprintf('%s_%d.png', classes{i}, j);
                copyfile(Ipaths{j}, fullfile(target_dir,path));
            end
        else
            path = sprintf('%s_%d.png', classes{i}, j);
        end
        if mod(j-1,img_per_line) == 0 && j ~= 1 && j ~= num_img
            fprintf(fid, '</tr>\n');
            generate_score_line(fid, score(deb_line:j-1), correct_label(deb_line:j-1), classes);
            deb_line = j;
            fprintf(fid, '<tr>\n');
        end
        fprintf(fid, '<td align="center">\n');
        generate_img(fid, path, sprintf('height="%d" title="Original path: %s"', img_size, Ipaths{j}));
        fprintf(fid, '</td>\n');
    end
    fprintf(fid,'</tr>\n');
    generate_score_line(fid, score(deb_line:num_img), correct_label(deb_line:num_img), classes);
    fprintf(fid,'</table>');
    fprintf(fid, '<br><font size="3"><a href="index.html">Back to index</a><br></font>\n');    
end

function generate_score_line(fid, scores, correct, classes)
    fprintf(fid, '<tr>\n');
    for i=1:length(scores)
        if correct(i)
            color = '#00AA44';
            class = '';
        else
            color = '#FF0000';
            class = '';
        end
        txt = sprintf('<font color="%s">%0.2f%s</font>', color, scores(i), class);
        fprintf(fid, '<td align="center">%s</td>\n', txt);
    end
    fprintf(fid, '</tr>\n');
end

function generate_img(fid, img_path, additional)
    if nargin < 3
        additional = '';
    end
    fprintf(fid, '<a href="%s"><img src="%s" %s /></a>\n', img_path, img_path, additional);
end


function file = lsvm_draw_boxes(target_dir, classifier, assigned_label, img, class, type, i)
    [dets parts] = classifier.get_boxes(assigned_label, img);
    if ~isempty(dets)
        img = draw_boxes_on_img(img, dets, parts, 3);
    end
    file = sprintf('%s_%s_%d.png', class, type, i);
    path = fullfile(target_dir, file);
    imwrite(img, path, 'png');
end

function img = draw_boxes_on_img(img, dets, parts, width)
    img = imread(img);
    
    c = dets(end-1);
    parts = [dets(1:4) parts(1:(end-2))];
    n_parts = length(parts) / 4;
    parts = reshape(parts, 4, n_parts)';   
    
    colors = [255   0   0; ...
              255   0   0; ...
              255 255   0; ...
              255 255   0; ...
                0 255   0; ...
                0 255   0; ...
                0 255   255; ...
                0 255   255; ...
                0   0 255];
    
    for i=2:n_parts
        [img dx dy] = draw_box_on_img(img, parts(i,:), colors(end,:), width);
        parts(:,[1 3]) = parts(:,[1 3]) + dx;
        parts(:,[2 4]) = parts(:,[2 4]) + dy;
    end
    
    img = draw_box_on_img(img, parts(1,:), colors(mod(c,size(colors,1)-1)+1,:), width);
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
