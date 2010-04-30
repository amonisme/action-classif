function extract(img_src, ann_src, img_dest, crop, resize, new_size, limit, scale, skip_ambiguous)
    if(nargin<5)
        resize = 0;
    end
    if(nargin<6)
        new_size = 300;
    end    
    if(nargin<7)
        limit = 150;
    end
    if(nargin<8)
        scale = 1.5;
    end
    if(nargin<9)
        skip_ambiguous = 1;
    end
    
    files = dir(img_src);
    num = [];
    for i=1:size(files,1)
        fprintf('%02d%%\n',floor(i*100/size(files,1)));
        if(files(i).isdir == 0)
            j = strfind(files(i).name,'.');
            [file errmsg] = sprintf('%s.xml',files(i).name(1:(j(1)-1)));
            img_name = fullfile(img_src, files(i).name);            
            xml_name = fullfile(ann_src, file);
            
            I = imread(img_name);
            XML = VOCreadxml(xml_name);
            
            ann = XML.annotation;
            if(isfield(ann,'object'))
                obj = ann.object;    
                for j=1:size(obj,2)
                    if(strcmp(obj(j).name,'person'))
                        bndbox = obj(j).bndbox;
                        xmin = str2double(bndbox.xmin);
                        xmax = str2double(bndbox.xmax);
                        ymin = str2double(bndbox.ymin);
                        ymax = str2double(bndbox.ymax);
                        
                        w = xmax-xmin;
                        h = ymax-ymin;
                        dw = ceil(w * (scale - 1)/2);
                        dh = ceil(h * (scale - 1)/2);
                        xmin = xmin-dw;
                        xmax = xmax+dw;
                        ymin = ymin-dh;
                        ymax = ymax+dh; 
                        
                        bb = [xmin ymin xmax ymax]-0.5;
                        
                        if(xmin<1) 
                            xmin = 1;
                        end
                        if(ymin<1)
                            ymin = 1;
                        end
                        if(xmax>size(I,2))
                            xmax = size(I,2); 
                        end
                        if(ymax>size(I,1)) 
                            ymax = size(I,1); 
                        end
                        
                        w = xmax-xmin+1;
                        h = ymax-ymin+1;
                        max_dim = max([w h]);
                        
                        if(max_dim < limit)
                            continue;
                        end
                            
                       if crop
                           J = I(ymin:ymax, xmin:xmax, :);
                           bb = [0 0 (xmax-xmin) (ymax-ymin)]+0.5;
                       else
                           J = I;
                       end
                       if resize
                           J = imresize(J, new_size/max_dim);
                           bb = bb * (new_size/max_dim);
                       end
                       bb = floor(bb)+1;
                       
                       if(isfield(obj(j),'action'))
                           act = obj(j).action;
                           for k=1:size(act,2)
                                if(skip_ambiguous)
                                    if(isfield(act(k),'ambiguous') && str2double(act(k).ambiguous))
                                        continue;
                                    end
                                end
                                dirname = fullfile(img_dest, act(k).actionname);
                                if(exist(dirname,'dir') == 0)
                                    mkdir(dirname);
                                end
                                n = 0;
                                for m=1:size(num,2)
                                    if(strcmp(num(m).name,act(k).actionname))
                                        n = m;
                                        break;
                                    end
                                end
                                if(n == 0)
                                    num = [num struct('name',act(k).actionname,'id',1)];
                                    n = size(num,1);
                                end
                                if(isfield(obj(j),'truncated'))
                                    trunc = obj(j).truncated;
                                else
                                    trunc = 0;
                                end
                                
                                file = sprintf('img%04d.jpg', num(n).id);
                                imwrite(J, fullfile(dirname, file), 'jpg');  
                                
                                file = sprintf('img%04d.info', num(n).id);
                                info = [str2double(trunc) bb];
                                save(fullfile(dirname, file), '-ascii', 'info');
                                
                                num(n).id = num(n).id + 1;
                           end
                       end
                    end
                end
            end
        end
    end
    
    classes = get_classes_files(img_dest);
    nclasses = size(classes,1);
   
    for i=1:nclasses
        fprintf('%s: %d\n', classes(i).name, size(classes(i).files,1));
    end
end


