function task_progress(tid, prg)
    persistent last_time;
    
    if isempty(last_time)
        last_time = -1;
    end
    
    curr_time = rem(now,1);
    if curr_time - last_time >= 0.0002  ...  % around 10 seconds
            || curr_time < last_time         % we passed midnight
        last_time = curr_time;
        fid = fopen(tid, 'w+');
        fwrite(fid, prg, 'float32');
        fclose(fid);
    end
end

