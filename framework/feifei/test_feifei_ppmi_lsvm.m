function test_feifei_ppmi_lsvm()
    db = {'feifei_bassoon' 'feifei_erhu' 'feifei_flute' 'feifei_frenchhorn' 'feifei_guitar' 'feifei_saxophone' 'feifei_violin'};
    
    for i=1:length(db)
        test_feifei_lsvm(db{i});
    end
end