function BMVC_latex_summary(file)
    global SHOW_BAR;
    SHOW_BAR = 0;

    dirs = {{'/data/vdelaitr/DataBaseCropped_test_SVM', 'Case A'}, ...
            {'/data/vdelaitr/DataBaseNoCrop_test_SVM', 'Case B'},  ...
            {'/data/vdelaitr/DataBaseNoCropResize_test_SVM', 'Case C1'},  ...
            {'/data/vdelaitr/DataBaseNoCropResize_test_SVM_CV', 'Case C2'},  ...
            {'/data/vdelaitr/DataBaseNoCropResize_test_SVM_FullGrid', 'Case C3'},  ...
            {'/data/vdelaitr/DataBaseNoCropResize_test_SVM_Concat', 'Case C4'},  ...
            {'/data/vdelaitr/DBGupta_test_SVM', 'Gupta Orig'}, ...
            {'/data/vdelaitr/DBGuptaResize_test_SVM' 'Gupta 600'}};

    fid = fopen(file, 'w+');
    
    generate_latex_header(fid, 'Results');    
    
    generate_latex_paragraphe(fid, '\textbf{Case A}: Images cropped to 1.5 the bounding box and rescaled s.t. the maximum of dimensions is 300');
    generate_latex_paragraphe(fid, '\textbf{Case B}: Original images (however there is a size limit of 500 pixels: no bigger images in the database)');
    generate_latex_paragraphe(fid, '\textbf{Case C1}: Images rescaled s.t. the maximum of the dimensions of the bounding box at 1.5 is 300. Their are two channels: $Chan_{BB}$ (signatures only from features inside the bounding box) and $Chan_{\overline{BB}}$ (signatures only from features outside the bounding box). When spatial pyramid is mentionned, it is applied only on $Chan_{BB}$. corresponding kernels are $K_{BB}$ and $K_{\overline{BB}}$ and the kernel given to the svm is K(X,Y) = $K_{BB}$(X,Y) + $K_{\overline{BB}}$(X,Y). In the case where $K_{BB}$ and $K_{\overline{BB}}$ have a parameter gamma (Chi2 and RBF), each gamma is assigned to the average distance between signatures (Chi2 or L2). The C parameter of the SVM is cross-validated.');
    generate_latex_paragraphe(fid, '\textbf{Case C2}: Same as case C1 but the gamma parameters of the kernels are cross-validated');
    generate_latex_paragraphe(fid, '\textbf{Case C3}: Same as case C2 but the channels are now $Chan_{BB}$ as previously and $Chan_{I}$ (signatures are computed on the whole image). In case of spatial pyramid, we apply a grid on the bounding box and another one on the full image.');
    generate_latex_paragraphe(fid, '\textbf{Case C4}: Same as case C1 but both channels $Chan_{BB}$ and $Chan_{\overline{BB}}$ are concatenated into a single channel $Chan_{C}$. Gamma parameter of the kernel is cross-validated.');    
    generate_latex_paragraphe(fid, '\textbf{Gupta Orig}: the original database of Gupta.'); 
    generate_latex_paragraphe(fid, '\textbf{Gupta 600}: the database of Gupta with images rescaled to 600 pixels for one of the dimensions.'); 
    
    generate_latex_summary(fid, dirs);
   
    generate_latex_section(fid, 'Detailled results');
    for i = 1:length(dirs)
        generate_latex_detail(fid, dirs{i}, i>6);
    end
        
    generate_latex_section(fid, 'All results');
    for i = 1:length(dirs)
        generate_latex_all_results(fid, dirs{i});
    end
    
    generate_latex_end(fid);
    
    fclose(fid);
end

function generate_latex_summary(fid, dirs)
    generate_latex_section(fid, 'Summary');

    n_dirs = length(dirs);
    error = zeros(n_dirs, 2);
    stdev = zeros(n_dirs, 2);
    row_names = cell(n_dirs,1);
    for i = 1:n_dirs
        current = dirs{i};
        [p d] = list_tests(current{1}, 0);
        [cv_score cv_stdev] = get_cv_score(current{1}, d{1});
        error(i, :) = p(1,:);
        stdev(i, 1) = cv_stdev;
        stdev(i, 2) = -1;
        row_names{i} = current{2};
    end
    
    table = result2table(error, stdev);
    
    generate_latex_paragraphe(fid, 'Best results for various databases (according to mean average precision)');
   
    generate_latex_table(fid, table, row_names, {'Mean average precision' 'Mean Accuracy'}); 
end

function table = result2table(perf, stdev)
    table = cell(size(perf));
    
    for i=1:size(perf, 1)
        for j=1:size(perf, 2)
            if nargin >= 2 && stdev(i,j) >= 0  % If standard deviation is provided
                table{i,j} = sprintf('$%0.2f \\\\pm %0.2f$', perf(i,j), stdev(i,j));
            else
                table{i,j} = sprintf('$%0.2f$', perf(i,j));
            end
        end
    end
end

function generate_latex_detail(fid, dir, isgupta)
    name = dir{2};
    dir = dir{1};
    
    [p d] = list_tests(dir, 0);
    
    generate_latex_subsection(fid, name); 
    
    %----
    generate_latex_subsubsection(fid,'Parameters');
    load(fullfile(dir,d{1},'classifier.mat'));   
    generate_latex_paragraphe(fid, regexprep(classifier.toString(),'\n', '\\\\\\\\\n'));
    
    %----
    generate_latex_subsubsection(fid,'Confusion Table');
    load(fullfile(dir,d{1},'results.mat'));   
    [acc_total acc_classes table] = get_accuracy(confusion_table(correct_label,assigned_label));

    table = result2table(table);
    
    if ~isgupta
        row_names = { ...
                    '(1) Interacting With Computer', ...
                    '(2) Photographing', ...
                    '(3) Playing Music', ...
                    '(4) Riding Bike', ...
                    '(5) Riding Horse', ...
                    '(6) Running', ...
                    '(7) Walking' ...                
                    }';
        col_names = { ...
                    '$~~$(1)$~~$', ...
                    '$~~$(2)$~~$', ...
                    '$~~$(3)$~~$', ...
                    '$~~$(4)$~~$', ...
                    '$~~$(5)$~~$', ...
                    '$~~$(6)$~~$', ...
                    '$~~$(7)$~~$' ...
                    };            
    else
        row_names = { ...
                    '(1) Cricket Batting', ...
                    '(2) Cricket Bowling', ...
                    '(3) Croquet', ...
                    '(4) Tennis Forehand', ...
                    '(5) Tennis Serve', ...
                    '(6) Volleyball Smash', ...
                    }';
        col_names = { ...
                    '$~~$(1)$~~$', ...
                    '$~~$(2)$~~$', ...
                    '$~~$(3)$~~$', ...
                    '$~~$(4)$~~$', ...
                    '$~~$(5)$~~$', ...
                    '$~~$(6)$~~$' ...
                    };           
    end

    fprintf(fid, '\\begin{small}\n');
    generate_latex_table(fid, table, row_names, col_names, 'Actions', sprintf('Mean accuracy: %0.2f\\%%',acc_total)); 
    fprintf(fid, '\\end{small}\n');
        
    %----
    generate_latex_subsubsection(fid,'Average Precision');
    
    n_classes = size(classes, 1);
    precision = size(n_classes, 1);
    
    for i=1:n_classes
        [rec,prec,ap] = precisionrecall(score(:, i), correct_label == i);
        ap = ap*100;
        

        precision(i) = ap;
        fprintf(fid, '%s: %0.2f\n\n', row_names{i}, precision(i));
    end
    [cv_score cv_stdev] = get_cv_score(dir, d{1});
    m_prec = mean(precision);
    if cv_stdev >= 0
        fprintf(fid, '\\textbf{Mean Average precision}: $%0.2f \\pm %0.2f$\n\n', m_prec, cv_stdev);
    else
        fprintf(fid, '\\textbf{Mean Average precision}: $%0.2f$\n\n', m_prec);
    end    
end

function generate_latex_all_results(fid, dir)
    name = dir{2};
    dir = dir{1};
    
    generate_latex_subsection(fid, name);    
    
    [p d] = list_tests(dir, 0);
    
    generate_latex_subsubsection(fid, 'Mean average precision / Mean accuracy / Parameters');
    fprintf(fid, '\\begin{small}\n');
    
    for i=1:size(d,2)
        fprintf(fid, '%0.2f / %0.2f / \\begin{tiny} %s \\end{tiny} \\\\ \n', p(i,1), p(i,2), d{i});
    end
    
    fprintf(fid, '\\end{small}\n');
end

function generate_latex_header(fid, title)
    fprintf(fid, '\\documentclass[10pt,a4paper]{article}\n\\usepackage{graphicx}\n\\usepackage{float}\n\\usepackage[tight,footnotesize]{subfigure}\n\\RequirePackage[table]{xcolor}%% for colored tabular rows \n\n\\title{%s}\n\n\\begin{document}\n\n\\maketitle\n\n', title);
end

function generate_latex_end(fid)
    fprintf(fid, '\\end{document}\n');
end


function generate_latex_section(fid, name)
    fprintf(fid, '%%==========================================================================\n\\section{%s}\n\n', name);
end

function generate_latex_subsection(fid, name)
    fprintf(fid, '%%--------------------------------------------------------------------------\n\\subsection{%s}\n\n', name);
end

function generate_latex_subsubsection(fid, name)
    fprintf(fid, '\\subsubsection{%s}$~$\\\n', name);
end

function generate_latex_paragraphe(fid, text)
    fprintf(fid, '%s\n\n', text);
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

