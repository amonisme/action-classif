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
        args = [sprintf('--loadRegions %s ', fullfile(back, dir, 'input')) args];
        write_input(fullfile(back, dir, 'input'), load_feat);
    end
    
    args = sprintf('%s --output %s --outputFormat binary %s', fullfile(back, Ipath), fullfile(back, dir, 'output'), args);
    [st res] = system([cmd args]);
    [feat descr] = read_output(fullfile(back, dir, 'output'));
end

