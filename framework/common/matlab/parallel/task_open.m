function tid = task_open()
    global TID IID TEMP_DIR;
    tid = fullfile(TEMP_DIR,TID,sprintf('info.%d', IID));
end

