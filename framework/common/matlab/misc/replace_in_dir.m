function replace_in_dir(d, str, rep_str)
    f = dir(d);
    for i=1:length(f)
        new_name = regexprep(f(i).name, str, rep_str);
        if ~strcmp(new_name, f(i).name)
            fprintf('Changed %s\n', f(i).name);
            orig_name = regexprep(f(i).name, '\(', '\\(');
            orig_name = regexprep(orig_name, '\)', '\\)');
            orig_name = regexprep(orig_name, '\[', '\\[');
            orig_name = regexprep(orig_name, '\]', '\\]');
            new_name = regexprep(new_name, '\(', '\\(');
            new_name = regexprep(new_name, '\)', '\\)');
            new_name = regexprep(new_name, '\[', '\\[');
            new_name = regexprep(new_name, '\]', '\\]');            
            cmd = sprintf('mv %s %s', orig_name, new_name)
            system(cmd);
        end
    end
end

