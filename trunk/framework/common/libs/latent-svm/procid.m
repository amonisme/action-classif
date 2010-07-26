function s = procid()

d = pwd();
if(strcmp(computer, 'PCWIN'))
    i = strfind(d, '\');
else
    i = strfind(d, '/');
end
d = d(i(end)+1:end);
s = d;
