function write_log(str, file)
    global OUTPUT_LOG;
    persistent fid;

    if(nargin == 2)
        fid = fopen(file, 'w+');
    end
    
    if OUTPUT_LOG == 1
        fprintf(fid, str);
    end
    fprintf(str);
end

