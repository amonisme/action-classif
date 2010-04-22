function stats = display_plots(X, Y, labelx, labely, graph_title, legends, do_regression)      
    scale = 0.2;
    xmin = +Inf;
    xmax = -Inf;
    ymin = +Inf;
    ymax = -Inf;
    
    d = size(X,1);
    for i=1:d
        if ~isempty(legends)
            scatter(X{i},Y{i},'DisplayName',legends{i});
        else
            scatter(X{i},Y{i});
        end
        hold on;
        xmin = min(xmin,min(X{i}));
        xmax = max(xmax,max(X{i}));
        ymin = min(ymin,min(Y{i}));
        ymax = max(ymax,max(Y{i}));            
    end
    
    dx = (xmax - xmin)*scale;
    dy = (ymax - ymin)*scale;       
        
    axis([(xmin-dx) (xmax+dx) (ymin-dy) (ymax+dy)]); 
    grid;
    xlabel(labelx);
    ylabel(labely);

    if ~isempty(legends)
        legend('show', 'Location', 'EastOutside');
    end
    
    if nargin >= 3 && do_regression
        X = cat(1,X{:});
        Y = cat(1,Y{:});
        stats = regstats(Y, X);
        plot([0 100], stats.beta'*[1 1;0 100], 'Color', 'black'); 
        title(sprintf('%s - Regression: Y = %.02f * X + %0.2f (mse = %0.2f)', graph_title, stats.beta(2), stats.beta(1), stats.mse));
    else
        title(graph_title);
    end
    
    hold off;
end

