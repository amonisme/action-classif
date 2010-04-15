function which_dir()
    % Use -nodesktop instead -nojvm if you need to start the Java Virtual
    % Machine
    cmd = sprintf('/usr/matlab-2009a/bin/matlab -nosplash -nodesktop -r "fprintf(''You should copy init_matlab.m into: %%s%%s'',cd,char(13)); exit"');
    system(cmd);
end

