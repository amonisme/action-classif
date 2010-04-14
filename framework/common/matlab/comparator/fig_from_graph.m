function fig_from_graph(graph)
    % Create figure
    fig = figure('OuterPosition', [300 300 800 600], 'PaperType', 'A5');
    
    % Create axes
    a = axes('Parent',fig,'XTick', 1:(size(graph.means,1)), 'XTickLabel',graph.names_points);
    set(a,'XGrid',graph.grid);
    set(a,'YGrid',graph.grid);    
    if ~isempty(graph.Yaxis)
        set(a, 'YLim', graph.Yaxis);
    end
    box(a,'on');
    hold(a,'all');
    
    % Create multiple lines using matrix input to plot
    if sum(sum(graph.stdev)) == 0 || ~graph.show_stdev
        p = plot(graph.means,graph.linespec,'Parent',a,'LineWidth', 2);
    else
        p = errorbar(graph.means,graph.stdev,graph.linespec,'Parent',a,'LineWidth', 2);
    end
    title(a, graph.title);
    for i = 1:(size(graph.means,2))
        set(p(i),'DisplayName',graph.name_curves{i});
    end
    
    % Create ylabel
    ylabel({''});
    
    % Create legend
    legend(a,'show', 'Location', 'EastOutside');
    
    % Save it
    if ~isempty(graph.file)
        print('-dpng', graph.file);
    end
end