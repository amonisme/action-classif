function [label score entropyBOF entropyLSVM] = select_scores(score_BOF, score_LSVM)
    entropyBOF = get_entropy(score_BOF); 
    entropyLSVM = get_entropy(score_LSVM);
    
    score = score_BOF;
    label = zeros(size(score,1), 1);
    for i=1:size(score,1)
        if ~compare_entropy(entropyBOF(i), entropyLSVM(i))
            score(i, :) = score_LSVM(i, :);
        end
        m = max(score(i,:));
        label(i) = find(score(i,:) == m,1);
    end
end

function entropy = get_entropy(score)
    center = zeros(size(score,1),1);
    st_dev = zeros(size(score,1),1);
    num_vote = zeros(size(score,1),1);    
    for i=1:size(score,1)
        I = isinf(score(i,:));
        center(i) = mean(score(i,~I));
        st_dev(i) = sqrt(var(score(i,~I)));
        num_vote(i) = length(find(~I));
    end
    entropy = st_dev / mean(st_dev(~isnan(st_dev)));
%     mean_st_dev = mean(st_dev(~isnan(st_dev)));
%     for i=1:size(score,1)
%         I = isinf(score(i,:));
%         score(i,I) = 1;
%         score(i,~I) = (score(i,~I) - center(i)) / mean_st_dev;
%     end               
%     entropy = geometrical_mean(score.*score, 2);        
%     entropy = sqrt(entropy);
    entropy(num_vote == 1) = Inf;        
    entropy(num_vote == 0) = NaN;
    score
end

function m = geometrical_mean(A, dim)
    m = prod(A, dim);
    m = m.^(1/size(A,dim));
end

function FirstIsBigger = compare_entropy(e1, e2)
    if isinf(e1)
        FirstIsBigger = 1;
    elseif isinf(e2)
        FirstIsBigger = 0;
    elseif isnan(e1)
        FirstIsBigger = 0;
    elseif isnan(e2)
        FirstIsBigger = 1;
    elseif e1 >= e2
        FirstIsBigger = 1;
    else
        FirstIsBigger = 0;
    end        
end