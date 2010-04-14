function graph = graph1D_sort_curves(graph)       
    perf_points = mean(graph.means, 2);
    [perf_points I] = sort(perf_points);
    graph.means = graph.means(I,:);
    graph.names_points = graph.names_points(I);

    perf_curves = graph.means(end,:);
    [perf_curves I] = sort(-perf_curves);
    graph.means = graph.means(:,I);
    graph.name_curves = graph.name_curves(I);

end