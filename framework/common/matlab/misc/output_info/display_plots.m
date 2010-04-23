function display_plots(points, graph_title, labelx, labely, leg, show_stdev, do_regression)
    if nargin < 6
        show_stdev = 0;
    end
    if nargin < 7
        do_regression = 0;
    end
    
    MarkerSize = 10;
    LineWidth = 2;
    scale = 0.2;
    
    xmin = min(cat(1, points(:).X));
    xmax = max(cat(1, points(:).X));
    ymin = min(cat(1, points(:).Y));
    ymax = max(cat(1, points(:).Y));
    dx = (xmax - xmin)*scale;
    dy = (ymax - ymin)*scale;                      
    
    % Create figure
    f = figure;
    
    % Ceate axes
    a = axes('Parent', f, 'FontSize',14,'FontName','Helvetica', 'XLim', [(xmin-dx) (xmax+dx)] , 'YLim', [(ymin-dy) (ymax+dy)]);
    box(a,'on');
    hold(a,'all');

    xlabel(labelx);
    ylabel(labely);
    title(graph_title);
    grid;
    
    d = size(points,1);
    for i=1:d
        if show_stdev
            errorbar(points(i).X,points(i).Y, points(i).stdev, points(i).marker, 'Color', points(i).color, 'LineWidth', LineWidth, 'MarkerSize', MarkerSize);
        else
            scatter(points(i).X, points(i).Y, MarkerSize*MarkerSize, points(i).color, points(i).marker, 'LineWidth', LineWidth);
        end
    end
    
    if ~isempty(leg)
        legend(a, leg.Strings, 'Location', leg.Location);
    end
    
    if do_regression
        X = cat(1,points(:).X);
        Y = cat(1,points(:).Y);
        stats = regstats(Y, X);
        plot([0 100], stats.beta'*[1 1;0 100], 'Color', 'black'); 
    end

    hold(a,'off');
end

