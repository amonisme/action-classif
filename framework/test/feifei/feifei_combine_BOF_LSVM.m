function feifei_combine_BOF_LSVM(root, alpha)
  db = {'feifei_bassoon' 'feifei_erhu' 'feifei_flute' 'feifei_frenchhorn' 'feifei_guitar' 'feifei_saxophone' 'feifei_violin'};
  %db = {'feifei_multi'};
  range = 0:0.01:1;
  prec = zeros(length(range),1);
  acc = zeros(length(range),1);
  
  for i=1:length(db)
      load(fullfile(root, sprintf('SVM_%s', db{i}), 'SVM[1vA-?-1-5]-Inter-PYR[c-1024-0-1x1x0.125+2x2x0.125+4x4x0.25+8x8x0.5-L1[1]-SIFT[cd-L2T[1-0.2]]-DENSE[my-6+1+2+4+6+8+11+15+19+24]]/results.mat'));
      score_BOF = score;
      load(fullfile(root, sprintf('LSVM_%s', db{i}), 'LSVM[1-9]/results.mat'));
      score_LSVM = score;
      [p a class_prec class_acc] = combine_BOF_LSVM(score_BOF, score_LSVM, classes, Ipaths, correct_label, range, alpha);            
      prec = prec + p;
      acc = acc + a;
      
      %alpha_per_class(range, class_prec, classes, 'Mean AP');
      %alpha_per_class(range, class_acc, classes, 'Mean accuracy');
  end
  
  prec = prec/length(db);
  acc = acc/length(db);
  
  % Plot the curve
  figure;
  plot(range, prec, range, acc);
  xlabel 'alpha';
  ylabel 'Performance';
  title 'score = alpha * scoreLSVM + (1-alpha) * scoreBOF';
  ymin = min([min(acc) min(prec)]);
  ymax = max([max(acc) max(prec)]);
  axis([0 1 (ymin-1) (ymax+1)]);
  grid;
  legend({'Mean av. prec.' 'Mean accuracy'}, 'Location', 'EastOutside');
end

function alpha_per_class(range, perf, classes, wintitle)
  % Alpha per class
  figure;
  plot(range, perf);
  xlabel 'alpha';
  ylabel 'Performance';
  title([wintitle ' - score = alpha * scoreLSVM + (1-alpha) * scoreBOF']);
  ymin = min(min(perf));
  ymax = max(max(perf));
  axis([0 1 (ymin-1) (ymax+1)]);
  grid;
  legend(classes, 'Location', 'EastOutside');
end