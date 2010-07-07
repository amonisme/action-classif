function [feat descr] = run_colorDescriptor(Ipath, args, load_feat)
    global FILE_BUFFER_PATH LIB_DIR;

    OS = computer;
    if(strcmp(OS, 'PCWIN'))
        %TODO
        throw(MException('','Windows not implemented'));
    else
        if(strcmp(OS, 'GLNX86'))
            dir = FILE_BUFFER_PATH;
            cmd = ['./' fullfile(LIB_DIR,'colordescriptors','i386-linux-gcc','colorDescriptor') ' --noErrorLog '];
            back = '';
        else
            if(strcmp(OS, 'GLNXA64'))
                dir = FILE_BUFFER_PATH;
                cmd = ['./' fullfile(LIB_DIR,'colordescriptors','x86_64-linux-gcc','colorDescriptor') ' --noErrorLog '];
                back = '';
            else            
                throw(MException('','Unknown OS'));
            end
        end
    end

    if(nargin == 3)
        input_file = fullfile(back,dir,'input');
        args = [sprintf('--loadRegions %s ', input_file) args];
        write_input(input_file, load_feat);
    end
    
    output_file = fullfile(back,dir,'output');
    args = sprintf('%s%s --output %s --outputFormat binary %s', back, Ipath, output_file, args);
    cmd = [cmd args];
    [st res] = system(cmd);    
    [feat descr] = read_output(output_file);
end

