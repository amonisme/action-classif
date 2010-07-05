function init_script(fun)
    global TID IID TEMP_DIR;
    
    cargs = load_file('args',TID,0); 
    pargs = load_file('args',TID,IID); 
    
    try 
        tic;
        args = fun(cargs, pargs); 
        t = toc;
    catch ME1
        fprintf(ME1.message); 
        fprintf(['in ' ME1.stack(1).file]); 
        fprintf([' line ' num2str(ME1.stack(1).line)]); 
        res = []; 
    end; 
    
    save(fullfile(TEMP_DIR,TID,sprintf('res_%d.mat',IID)), 'args', 't');
    
    system(sprintf('mv %s %s',fullfile(TEMP_DIR,TID,sprintf('res_%d.mat',IID)),fullfile(TEMP_DIR,TID,sprintf('res%d.mat',IID)))); 
    exit;
end
