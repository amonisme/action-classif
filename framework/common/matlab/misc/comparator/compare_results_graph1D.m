function graph = compare_results_graph1D(res, names, plot_dim, curve_dims, permut, Yaxis, file, grid, show_stdev, title, linespec) 
    s = size(res);
    n_points = s(plot_dim);
    n_curves = prod(s(curve_dims));
    
    if nargin < 5
        permut = [];
    end
    if nargin < 6
        Yaxis = [];
    end    
    if nargin < 7
        file = '';
    end
    if nargin < 8
        grid = 'off';
    end     
    if nargin < 9
        show_stdev = 0;
    end
    if nargin < 10
        title = '';
    end             
    if nargin < 11
        linespec = '';
    end      
    if isnumeric(grid)
        if grid
            grid = 'on';
        else
            grid = 'off';
        end
    end
    
    graph =  struct('means', zeros(n_points, n_curves), 'stdev', zeros(n_points, n_curves), 'names_points', [], 'name_curves', [], 'show_stdev', show_stdev, 'Yaxis', Yaxis, 'title', title, 'grid', grid, 'file', file, 'linespec', linespec);
    graph.names_points = get_labels(names, plot_dim);
    
    for i = 1:n_points
        coords = zeros(1, length(s));
        coords(plot_dim) = i;
        [m sd n] = rec_get_curves(res, names, coords, curve_dims);
        graph.means(i,:) = m;
        graph.stdev(i,:) = sd;
        if i == 1
            graph.name_curves = n;
        end
    end
        
    graph = graph1D_sort_curves(graph);
    
    if ~isempty(permut)
        graph = graph1D_permut_curves(graph, permut);
    end
    
    fig_from_graph(graph);
end

function [means stdev curve_names] = rec_get_curves(res, names, coords, curves_dims)
    if isempty(curves_dims)
        vals = rec_get_vals(res, 1, coords);
        means = mean(vals);
        stdev = vals - means;
        stdev = sqrt(sum(stdev.*stdev));
        curve_names= {};
    else
        s = size(res);
        dim = curves_dims(1);
        means = [];
        stdev = [];
        curve_names = cell(1,s(dim));
        for i = 1:s(dim)
            coords(dim) = i;
            [m sd n] = rec_get_curves(res, names, coords, curves_dims(2:end));
            means = [means m];
            stdev = [stdev sd];
            curve_names{i} = cell(1,length(n));
            prefix = get_labels(names, dim);
            prefix = prefix{i};
            if ~isempty(n)
                prefix = [prefix ' '];
                for j = 1:length(n);
                    curve_names{i}{j} = [prefix n{j}];
                end                             
                curve_names = cat(2,curve_names{:});
            else
                curve_names{i} = prefix;
            end            
        end
    end    
end

function vals = rec_get_vals(r, i, coords)
    next = find(coords((i+1):end) == 0, 1) + i;
    if isempty(next)
        s = size(r);
        if coords(i) == 0
            k = zeros(1, s(i));
            for j = 1:s(i)
                coords(i) = j;
                k(j) = mysub2ind(s,coords);
            end
            vals = r(k);
        else
            vals = r(mysub2ind(s,coords));
        end
    else
        if coords(i) == 0
            s = size(r);
            vals = cell(1,s(i));
            for j = 1:s(i)
                coords(i) = j;
                vals{j} = rec_get_vals(r, next, coords);
            end
            vals = cat(2, vals{:});
        else
            vals = rec_get_vals(r, next, coords);
        end
    end
end

function labels = get_labels(names, dim)
    labels = keys(names{dim});
    orders = values(names{dim});
    [orders, I] = sort([orders{:}]);
    labels = labels(I);    
end