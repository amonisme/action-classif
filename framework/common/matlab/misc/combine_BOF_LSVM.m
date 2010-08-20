function [opt_alphas score p a prec acc class_prec class_acc] = combine_BOF_LSVM(score_BOF, score_LSVM, classes, images, alpha)
    do_plot = 1;
    path = './';

    step = 0.01;
    alpha_range = 0:step:1;
    if nargin < 5
        alpha = 0.5;
    end
    
    correct_label = cat(1, images(:).actions);
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
    
    [p a cp ca score] = combine(score_BOF, score_LSVM, alpha, correct_label);
    fprintf('Accuracy: %f\nmAP: %f\n', a, p);
    

    opt_alphas = zeros(1, n_classes);
    if do_plot
        prec = smooth_curve(prec, 0.1);
        acc = smooth_curve(acc, 0.1);
        plot_curve(alpha_range, prec, acc, 'score = alpha * scoreLSVM + (1-alpha) * scoreBOF');
        if ~isempty(path)
            print('-dpng ', fullfile(path,'global.png'));
        end
    end
    for i=1:n_classes
        prec = smooth_curve(class_prec(:,i), 0.1);
        acc = smooth_curve(class_acc(:,i), 0.1);
        if do_plot
            plot_curve(alpha_range, prec, acc, classes{i});
            if ~isempty(path)
                print('-dpng ', fullfile(path,sprintf('%s.png', classes{i})));
            end
        end
        [m I] = max(prec);
        opt_alphas(i) = (I-1) * step;
    end
end

function [prec acc class_prec class_acc score] = combine(score_BOF, score_LSVM, alpha, correct_label)
    if isscalar(alpha)
        score = alpha*score_LSVM + (1-alpha)*score_BOF;
    else
        for i=1:size(score_BOF,2);
            score_LSVM(:,i) = score_LSVM(:,i) * alpha(i);
            score_BOF(:,i)  = score_BOF(:,i)  * (1-alpha(i));            
        end
        score = score_LSVM + score_BOF;
    end
    
    n_classes = size(score_BOF, 2);
    class_acc = zeros(n_classes,1);
    class_prec = zeros(n_classes,1);
    for i=1:size(score,1)
        m = max(score(i,:));
        j = find(score(i,:) == m,1);
        if correct_label(i,j)
            class_acc(j) = class_acc(j) + 1;
        end
    end
    
    for i = 1:n_classes
        class_acc(i) = class_acc(i) * 100 / length(find(correct_label(:,i)));        
        [r1,r2,ap] = precisionrecall(score(:, i), correct_label(:,i));
        class_prec(i) = ap * 100;   
    end
    
    acc = mean(class_acc);
    prec = mean(class_prec);    
end


function plot_curve(alpha, prec, acc, curve_title)
    figure;
    plot(alpha, prec, alpha, acc);
    xlabel 'alpha';
    ylabel 'Performance';
    title(curve_title);
    ymin = min([min(acc) min(prec)]);
    ymax = max([max(acc) max(prec)]);
    axis([0 1 (ymin-1) (ymax+1)]);
    grid;
    legend({'Mean av. prec.' 'Mean accuracy'}, 'Location', 'EastOutside');
end

function out = smooth_curve(in, window_width)
    window_half_width = floor(window_width / 2 * 100) / 100;
    sigma = window_half_width / 3;
    window = (-window_half_width):0.01:window_half_width;
    filter = window_width * window_width / (sigma * sqrt(2*pi)) * exp(-window.^2 / (2*sigma^2));
    filter = filter';
        
    out = in;
    filter_size = length(window);
    filter_half_size = (filter_size - 1) / 2;
    size_in = length(in);
    for i = 1:size_in
        bi = i - filter_half_size;
        if bi<1            
            bf = 1 + (1 - bi);
            bi = 1;
        else
            bf = 1;
        end
        ei = i + filter_half_size;
        if ei>size_in
            ef = filter_size - (ei - size_in);
            ei = size_in;
        else
            ef = filter_size;
        end
        out(i) = sum(in(bi:ei) .* filter(bf:ef)) / sum(filter(bf:ef));
    end
end