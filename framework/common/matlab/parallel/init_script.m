function init_script(fun)
    global TID IID TEMP_DIR;
    
    cargs = load_file('args',TID,0); 
    pargs = load_file('args',TID,IID); 
    
    try 
        res = fun(cargs, pargs); 
    catch ME1
        fprintf(ME1.message); 
        fprintf(['in ' ME1.stack(1).file]); 
        fprintf([' line ' num2str(ME1.stack(1).line)]); 
        res = []; 
    end; 
    
    save_file('res',TID,IID,res); 
    system(sprintf('mv %s %s',fullfile(TEMP_DIR,TID,sprintf('res_%d.mat',IID)),fullfile(TEMP_DIR,TID,sprintf('res%d.mat',IID)))); 
    exit;
end
