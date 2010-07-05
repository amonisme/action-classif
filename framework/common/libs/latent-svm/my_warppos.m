function warpped = my_warppos(model, pos)

% warped = warppos(name, model, pos)
% Warp positive examples to fit model dimensions.
% Used for training root filters from positive bounding boxes.

globals;

fi = model.symbols(model.rules{model.start}.rhs).filter;
fsize = model.filters(fi).size;
numpos = length(pos);
warpped = cell(numpos);
cropsize = (fsize+2) * model.sbin;
for i = 1:numpos
  fprintf('%s: warp: %d/%d\n', model.class, i, numpos);
  x1 = round(pos(i).x1);
  x2 = round(pos(i).x2);
  y1 = round(pos(i).y1);
  y2 = round(pos(i).y2);
  I = pos(i).feat(:,1) >= x1 & pos(i).feat(:,1) <= x2 & ...
      pos(i).feat(:,2) >= y1 & pos(i).feat(:,2) <= y2;
  feat = pos(i).feat(I,:);
  feat(:,1) = (feat(:,1) - (x1 - 1)) / (x2 - x1 + 1) * cropsize(2);
  feat(:,2) = (feat(:,2) - (y1 - 1)) / (y2 - y1 + 1) * cropsize(1);
  warpped{i} = struct('size', cropsize, 'feat', feat);  
end
