function test_sift(path1, path2)
    global STEP_TEST DESCR_TEST SIZE_TEST HASH_PATH;   
    HASH_PATH = [];
    
    Ipaths = {path1 path2}';

    feat = cell(2,1);
    
    STEP_TEST = 1;
    
    info1 = imfinfo(path1);
    feat{1} = zeros(ceil(info1.Width/STEP_TEST)*ceil(info1.Height/STEP_TEST), 5);
    for i=1:STEP_TEST:info1.Width
        for j=1:STEP_TEST:info1.Height
            feat{1}((ceil(i/STEP_TEST)-1)*ceil(info1.Height/STEP_TEST)+ceil(j/STEP_TEST),:) = [i j 2 0 0];
        end
    end
    
    info2 = imfinfo(path2);
    feat{2} = zeros(ceil(info2.Width/STEP_TEST)*ceil(info2.Height/STEP_TEST), 5);
    for i=1:STEP_TEST:info2.Width
        for j=1:STEP_TEST:info2.Height
            feat{2}((ceil(i/STEP_TEST)-1)*ceil(info2.Height/STEP_TEST)+ceil(j/STEP_TEST),:) = [i j 2 0 0];
        end
    end
    
    pg = ProgressBar('', '');
    DESCR_TEST = SignatureAPI.compute_descriptors(Dense, SIFT(L2Trunc), Ipaths, feat, pg, 0, 1);  
    SIZE_TEST = ceil([info1.Width info1.Height; info2.Width info2.Height]/STEP_TEST);
    pg.close();
    
    h = figure;
    imshow(path1);
    set(get(get(h, 'Children'), 'Children'),'ButtonDownFcn',@show_img1);
    
    h = figure;
    imshow(path2);  
    set(get(get(h, 'Children'), 'Children'),'ButtonDownFcn',@show_img2);
end

function show_img1(src, event)
    global STEP_TEST DESCR_TEST SIZE_TEST;
    
    point = get(get(src,'Parent'), 'CurrentPoint');
    mouse_x = point(1,1);
    mouse_y = point(1,2);
    
    d = DESCR_TEST{1}((ceil(mouse_x/STEP_TEST)-1) * SIZE_TEST(1,2) + ceil(mouse_y/STEP_TEST),:);
    map = (DESCR_TEST{2} * d') .^ 3;
    map = reshape(map, SIZE_TEST(2,2), SIZE_TEST(2,1));
    
    figure
    imshow(map);
end

function show_img2(src, event)
    global STEP_TEST DESCR_TEST SIZE_TEST;
    
    point = get(get(src,'Parent'), 'CurrentPoint');
    mouse_x = point(1,1);
    mouse_y = point(1,2);
    
    d = DESCR_TEST{2}((ceil(mouse_x/STEP_TEST)-1) * SIZE_TEST(2,2) + ceil(mouse_y/STEP_TEST),:);
    map = (DESCR_TEST{1} * d') .^ 3;
    map = reshape(map, SIZE_TEST(1,2), SIZE_TEST(1,1));
    
    figure
    imshow(map);
end