function BMVC_show_misclassified(root, file, prefix, index, Ipath, classes, label, correct)
    fid = fopen(fullfile(root, file), 'w+');
    
    img_height = '2cm';
    n_img = 1000;
    height = 500;
    
    index = index(randperm(length(index)));
    table = {};
    for k = 1:n_img
        if k > length(index) 
            break;
        end
        i = index(k);
        
        img = imread(Ipath{i});
        [bb bb_crop]= get_bb_info(Ipath{i});
        [h w d] = size(img);
        
        img = draw_box_on_img(img, bb_crop(2:end), [255 0 0], 3);
        new_width = w * height / h;
        img = imresize(img, [height new_width]);
        
        correct_lbl = classes{correct(i)};
        classif_lbl = classes{label(i)};
        
        [d f] = fileparts(Ipath{i});
        img_name = sprintf('%s%s_instead_%s_%s.png',prefix,classif_lbl,correct_lbl,f);
        imwrite(img, fullfile(root, img_name), 'png');
        
        graphic = sprintf('\\\\includegraphics[height=%s]{figs/%s}', img_height, img_name);
               
        table = [table {graphic; correct_lbl; classif_lbl}];        
    end
    
    generate_latex_table(fid, table, {'Images'; 'Correct label'; 'Result label'});    
    
    fclose(fid);
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

function generate_latex_table(fid, table, row_names, col_names, corner_name, caption)
    fprintf(fid, '\\begin{table}[H]\n\\centering\n');
    
    if nargin >= 6
        fprintf(fid, '\\caption{%s}\n', caption);
    end
    
    fprintf(fid, '\\rowcolors[]{1}{white}{gray!10}');
    
    num_row = size(table,1) + (nargin>=4 && ~isempty(col_names));
    num_col = size(table,2) + (nargin>=3 && ~isempty(row_names));
    
    fprintf(fid, '\\begin{tabular}{%s|}\n\\hline\n', repmat('|c', 1, num_col));
    
    if nargin>=3 && ~isempty(row_names)
        table = [row_names table];
        
        if nargin>=4 && ~isempty(col_names)
            if nargin >= 5
                col_names = [corner_name col_names];
            else
                col_names = [' ' col_names];
            end
        end
    end
    
    if nargin>=4 && ~isempty(col_names)
        table = [col_names; table];
    end

    for i=1:size(table, 1)
        for j=1:size(table, 2)
            if j > 1
                fprintf(fid, ' & ');
            end
            fprintf(fid, table{i,j});            
        end
        fprintf(fid, '\\\\ \\hline \n');
    end
       
    fprintf(fid, '\\end{tabular}\n\\end{table}\n');
end
