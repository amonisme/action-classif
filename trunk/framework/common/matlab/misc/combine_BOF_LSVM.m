function [prec acc class_prec class_acc] = combine_BOF_LSVM(score_BOF, score_LSVM, classes, Ipaths, correct_label, alpha_range, alpha)
    if nargin < 7
        alpha = 0.5;
    end
    
    n_classes = length(classes);
    acc = zeros(length(alpha_range),1);
    prec = zeros(length(alpha_range),1);
    class_prec = zeros(length(alpha_range),n_classes);
    class_acc = zeros(length(alpha_range),n_classes);
    for i=1:length(alpha_range)
        [p a cp ca] = combine(score_BOF, score_LSVM, alpha_range(i), correct_label);        
        prec(i) = p;
        acc(i) = a;
        class_prec(i,:) = cp';
        class_acc(i,:) = ca';
    end   
    
    % Save results
    res_dir = 'combine';    
    if ~isdir(res_dir)
        mkdir(res_dir);
    end
    [p a cp ca score] = combine(score_BOF, score_LSVM, alpha, correct_label);
    assigned_label = zeros(size(score,1), 1);
    for i=1:size(score,1)
        m = max(score(i,:));
        assigned_label(i) = find(score(i,:) == m,1);
    end    
    save(fullfile(res_dir, 'results.mat'),'Ipaths','classes','correct_label','assigned_label','score');
    
    fid = fopen(fullfile(res_dir,'accuracy.txt'), 'w+');
    fwrite(fid, num2str(a), 'char');
    fclose(fid);    
    
    fid = fopen(fullfile(res_dir,'precision.txt'), 'w+');
    fwrite(fid, num2str(p), 'char');
    fclose(fid);
    
    display_results(res_dir,0,'');
    
    % Plot the curve
    figure;
    plot(alpha_range, prec, alpha_range, acc);
    xlabel 'alpha';
    ylabel 'Performance';
    title 'score = alpha * scoreLSVM + (1-alpha) * scoreBOF';
    ymin = min([min(acc) min(prec)]);
    ymax = max([max(acc) max(prec)]);
    axis([0 1 (ymin-1) (ymax+1)]);
    grid;
    legend({'Mean av. prec.' 'Mean accuracy'}, 'Location', 'EastOutside');
end

function [prec acc class_prec class_acc score] = combine(score_BOF, score_LSVM, alpha, correct_label)
    score = alpha*score_LSVM + (1-alpha)*score_BOF;
    
    n_classes = max(correct_label);
    class_acc = zeros(n_classes,1);
    class_prec = zeros(n_classes,1);
    for i=1:size(score,1)
        m = max(score(i,:));
        j = find(score(i,:) == m,1);
        if j == correct_label(i)
            class_acc(j) = class_acc(j) + 1;
        end
    end
    
    for i = 1:n_classes
        class_acc(i) = class_acc(i) * 100 / length(find(correct_label == i));        
        [r1,r2,ap] = precisionrecall(score(:, i), correct_label == i);
        class_prec(i) = ap * 100;   
    end
    
    acc = mean(class_acc);
    prec = mean(class_prec);    
end
