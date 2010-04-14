function display_img(N, dir, prefix, root)
    if nargin < 3
            prefix = '';
    end
    if nargin < 4
        root = 'experiments';
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
    
    fid = fopen(fullfile('experiments', file), 'w+');
    fprintf(fid, '\\documentclass[10pt,a4paper]{article}\n\\usepackage{graphicx}\n\\usepackage{float}\n\\usepackage[tight,footnotesize]{subfigure}\n\n\\title{%s}\n\n\\begin{document}\n\n\\maketitle\n\n', regexprep(classifier.toFileName(),'_', '\\_'));
           
    fprintf(fid, regexprep(classifier.toString(),'\n', '\\\\\\\\\n'));
    
    for i=1:n_classes
        
        fprintf(fid, '\\section{%s}\n', classes{i});        
        
        % Compute PR
        [rec,prec,ap,sortind] = precisionrecall(score(:, i), correct_label == i);
        ap = ap*100;
        Ipath = Ipaths(sortind);
        correct = correct_label(sortind);
        assigned = assigned_label(sortind);
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
        fprintf(fid,'\\begin{figure}[H]\n\\centering\n');
        for j = 1:n
            fprintf(fid,'\\subfigure[%.2f]{\\includegraphics[height=3cm]{../%s}}\n', sc(I(j)), Ipath{I(j)});
        end
        fprintf(fid,'\\caption{%s: Correctly classified images, highest score}\n\\end{figure}\n', classes{i});
        
        % Correctly classified images, smallest score
        fprintf(fid,'\\begin{figure}[H]\n\\centering\n');
        for j = n:-1:1
            fprintf(fid,'\\subfigure[%.2f]{\\includegraphics[height=3cm]{../%s}}\n', sc(I(end-j+1)), Ipath{I(end-j+1)});
        end
        fprintf(fid,'\\caption{%s: Correctly classified images, smallest score}\n\\end{figure}\n', classes{i});
        
        % Misclassified images, highest score
        I = find(assigned == i & correct ~= i, N);
        fprintf(fid,'\\begin{figure}[H]\n\\centering\n');
        for j = 1:length(I)
            fprintf(fid,'\\subfigure[%.2f]{\\includegraphics[height=3cm]{../%s}}\n', sc(I(j)), Ipath{I(j)});                    
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

