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
        args = [sprintf('--loadRegions %s%sinput ',back, dir) args];
        write_input([back dir 'input'], load_feat);
    end
    
    args = sprintf('%s%s --output %s%soutput --outputFormat binary %s', back, Ipath, back, dir, args);
    cmd = [cmd args];
    [st res] = system(cmd);
    [feat descr] = read_output([back dir 'output']);
end

