function [precision accuracy] = get_prec_acc(root, d)
    accuracy_file = fullfile(root,d,'accuracy.txt');
    precision_file = fullfile(root,d,'precision.txt');
    if exist(accuracy_file,'file') == 2 && exist(precision_file,'file') == 2
        fid = fopen(precision_file,'r');
        p = fread(fid, 100, 'uint8=>char')';
        fclose(fid);
        precision = str2double(p);

        fid = fopen(accuracy_file,'r');
        p = fread(fid, 100, 'uint8=>char')';
        fclose(fid);
        accuracy = str2double(p);
    else
        precision = [];
        accuracy = [];        
    end
end

