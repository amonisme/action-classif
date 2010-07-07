function my_writemodel(modfile, model)

blocks = cell(model.numblocks, 1);

% filters
for i = 1:model.numfilters
  if model.filters(i).flip == 0
    bl = model.filters(i).blocklabel;
    type = model.filters(i).type; % MYMOD
    if type == 'H' || type == 'A'
        wHOG = model.filters(i).w(:);    
        wHOG = reshape(wHOG, numel(wHOG), 1);
    else
        wHOG = [];
    end
    if type == 'B' || type == 'A'
        wBOF = model.filters(i).histo(:);
    else
        wBOF = [];
    end
    blocks{bl} = [wHOG; wBOF];    
  end
end

% offsets
for i = 1:length(model.rules)
  for j = 1:length(model.rules{i})
    bl = model.rules{i}(j).offset.blocklabel;
    blocks{bl} = model.rules{i}(j).offset.w;
  end
end

% deformation models
for i = 1:length(model.rules)
  for j = 1:length(model.rules{i})
    if model.rules{i}(j).type == 'D' && model.rules{i}(j).def.flip == 0
      bl = model.rules{i}(j).def.blocklabel;
      blocks{bl} = model.rules{i}(j).def.w(:);
    end
  end
end

% concatenate
m = [];
for i = 1:model.numblocks
  m = [m; blocks{i}];
end

% sanity check
if sum(model.blocksizes) ~= length(m)
  error('model size error');
end

% write to modfile
fid = fopen(modfile, 'wb');
fwrite(fid, m, 'double');
fclose(fid);
