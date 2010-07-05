function model = parsemodel(model, blocks, i)

% parsemodel(model, blocks)
% Update model parameters from weight vector representation.

if nargin < 3
  i = model.start;
end

if model.symbols(i).type == 'T'
  % i is a terminal/filter
  % save filter weights from blocks
  fi = model.symbols(i).filter;
  doHOG = model.filters(fi).type == 'H' || model.filters(fi).type == 'A';
  doBOF = model.filters(fi).type == 'B' || model.filters(fi).type == 'A';
  
  if model.filters(fi).type == 'A'
    blockHOG = blocks{model.filters(fi).blocklabel}(1:numel(model.filters(fi).w));
    blockBOF = blocks{model.filters(fi).blocklabel}((numel(model.filters(fi).w)+1):end);
  elseif model.filters(fi).type == 'H'
    blockHOG = blocks{model.filters(fi).blocklabel};
  else
    blockBOF = blocks{model.filters(fi).blocklabel};
  end
      
  if model.filters(fi).symmetric == 'M'
    if doHOG
      f = reshape(blockHOG, size(model.filters(fi).w));
      if model.filters(fi).flip
        f = flipfeat(f);
      end
      model.filters(fi).w = f;
    end
    if doBOF
      model.filters(fi).histo = reshape(blockBOF, size(model.filters(fi).histo));  
    end    
  elseif model.filters(fi).symmetric == 'N'
    f = reshape(blockHOG, size(model.filters(fi).w));
    model.filters(fi).w = f;
  else
    error('unknown filter symmetry type');
  end
else
  % i is a non-terminal
  for r = rules_with_lhs(model, i)
    model.rules{r.lhs}(r.i).offset.w = blocks{r.offset.blocklabel};
    if r.type == 'D'
      sz = size(model.rules{r.lhs}(r.i).def.w);
      model.rules{r.lhs}(r.i).def.w = reshape(blocks{r.def.blocklabel}, sz);
      if r.def.symmetric == 'M' && r.def.flip
        % flip linear term in horizontal deformation model
        model.rules{r.lhs}(r.i).def.w(2) = -model.rules{r.lhs}(r.i).def.w(2);
      end
    end
    for s = r.rhs
      % recurse
      model = parsemodel(model, blocks, s);
    end
  end
end
