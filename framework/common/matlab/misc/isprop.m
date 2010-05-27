function res = isprop(obj, name)
    res = ~isempty(find(strcmp(name, properties(obj)), 1));
end

