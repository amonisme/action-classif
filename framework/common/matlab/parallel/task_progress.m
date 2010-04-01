function task_progress(tid, prg)
    fid = fopen(tid, 'w+');
    fwrite(fid, prg, 'float32');
    fclose(fid);
end

