function graph = graph1D_filter_curves(graph, I)
    graph.means = graph.means(:,I);
    graph.stdev = graph.stdev(:,I);
    graph.name_curves = graph.name_curves(:,I);
end

