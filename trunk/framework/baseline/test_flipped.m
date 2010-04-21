function test_flipped()
    global USE_PARALLEL SHOW_BAR;
    USE_PARALLEL = 1;
    SHOW_BAR = 1;   
    
    %SVM[1vA-?-1-5-Inter]-PYR[cpp-1024-1x1x0.25+2x2x0.25+4x4x0.5-L2[1]]-DEN
    %SE[mylib-12+2+5+8+12+17+23+30+39+49]xSIFT[cd-L2T[1-0.2]]
    
    database = '../DataBaseFlipped/';
    dir = 'baseline/test_flipped';
    [status,message,messageid] = mkdir(dir);

    classifier = SVM(Chi2([],1),BOF(Channels({MS_Dense}, {SIFT(L2Trunc)}), 1024, L2, [1 1 0.25; 2 2 0.25; 4 4 0.5]), 'OneVsAll', [], 1, 5);           
    evaluate(classifier, database, dir);
end
