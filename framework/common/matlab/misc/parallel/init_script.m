function init_script(fun)
    global TID IID TEMP_DIR;
    
    cargs = load_file('args',TID,0); 
    pargs = load_file('args',TID,IID); 
    
    try 
        t1 = clock;
        args = fun(cargs, pargs); 
        t2 = clock;
        t = etime(t2, t1);
        save(fullfile(TEMP_DIR,TID,sprintf('res_%d.mat',IID)), 'args', 't');    
        system(sprintf('mv %s %s',fullfile(TEMP_DIR,TID,sprintf('res_%d.mat',IID)),fullfile(TEMP_DIR,TID,sprintf('res%d.mat',IID))));            
    catch ME1
        fprintf('Error in parallel task:\n');
        fprintf(ME1.message); 
        fprintf(['in ' ME1.stack(1).file]); 
        fprintf([' line ' num2str(ME1.stack(1).line)]); 
        fprintf('\n-----\n\n');
    end;    
    exit;    
end