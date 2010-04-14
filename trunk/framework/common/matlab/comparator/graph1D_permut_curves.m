function graph = graph1D_permut_curves(graph, permut)        
    graph.means = graph.means(permut,:);
    graph.names_points = graph.names_points(permut);
end