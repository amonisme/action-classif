function coef_overlap = inter_box(box1, boxes2)
    box1 = order_box(box1);
    n_boxes = size(boxes2,1);
    coef_overlap = zeros(n_boxes,1);
    
    a1 = box_area(box1);
    for i=1:n_boxes
        b = order_box(boxes2(i,:));
        x1 = max([b(1) box1(1)]);
        x2 = min([b(3) box1(3)]);
        if x1<=x2
            y1 = max([b(2) box1(2)]);
            y2 = min([b(4) box1(4)]);
            if y1<=y2
                inter = box_area([x1 y1 x2 y2]);
                a2 = box_area(b);
                coef_overlap(i) = inter / (a1 + a2 - inter);
            end            
        end
    end    
end

function box = order_box(box)
    box = [min(box([1 3])) min(box([2 4])) max(box([1 3])) max(box([2 4]))];
end

function a = box_area(box)
    a = (box(3) - box(1) + 1) * (box(4) - box(2) + 1);
end