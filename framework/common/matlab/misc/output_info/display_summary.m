function display_summary(root_BOF, root_PYR)
    [c1 c2 points_BOF points_PYR] = get_paper_BMVC_classif(root_BOF, root_PYR);
     
    points = prepare_points_for_plot(2);
    points(1).X = cat(1, points_BOF(:).X);
    points(1).Y = cat(1, points_BOF(:).Y);
    points(1).stdev = cat(1, points_BOF(:).stdev);
    points(1).color = [0 0 0];
    points(1).marker = '*';
    points(2).X = cat(1, points_PYR(:).X);
    points(2).Y = cat(1, points_PYR(:).Y);
    points(2).stdev = cat(1, points_PYR(:).stdev);
    points(2).color = [1 0.53 0];
    points(2).marker = '^';    
    
    l = struct('Strings', [], 'Location', 'NorthWest');
    l.Strings = {'Bag of words', 'Spatial pyramid'};
    display_plots(points, 'BOF & Spatial Pyramid perfomances for various kernels & dictionnary size', 'Test error in %', 'Validation error in %', l, 0);
    l = struct('Strings', [], 'Location', 'EastOutside');
    l.Strings = {'Linear',  ...
                 'RBF',  ...
                 'Intersection',  ...
                 'Chi2'};
    display_plots(points_PYR, 'Spatial Pyramid perfomances for various kernels & dictionnary size', 'Test error in %', 'Validation error in %', [], 0);
end

