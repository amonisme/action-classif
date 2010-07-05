function onclick(src,evnt)
    global DESCR IMGSIZE;

    point = get(get(src,'Parent'), 'CurrentPoint');
    mouse_x = floor(point(1,1));
    mouse_y = floor(point(1,2));
   
    img = zeros(IMGSIZE);
    
    for x=1:IMGSIZE(2)
        for y=1:IMGSIZE(1)
            img(y,x) = sum(DESCR(y,x,:) .* DESCR(mouse_y, mouse_x,:));
        end
    end
            
    figure;        
    imagesc(img);
end