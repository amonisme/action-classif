function [m, symbol, filterind] = model_addfilter(m, w, symmetric, type, blocklabel, flip)
% Add a filter to the model.  Automatically allocates a new block if blocklabel is empty.
%
% m           object model
% w           filter weights
% symmetric   'M'irrored or 'N'one
% type        'H'og / 'B'of / 'A'll
% blocklabel  block to use for the filter weights
% flip        is this filter vertically flipped

% set argument defaults
if nargin < 3
  symmetric = 'N';
end

if nargin < 4
  type = 'B';
end

if nargin < 5
  blocklabel = [];
end

if nargin < 6
  flip = false;
end

% M = vertical mirrored partner
% N = none (no symmetry)
if symmetric ~= 'M' && symmetric ~= 'N'
  error('parameter symmetric must be either M or N');
end

% get index for new filter
j = m.numfilters + 1;
m.numfilters = j;

% get new blocklabel
% MYMOD
doHOG = (type == 'H' || type == 'A');
doBOF = (type == 'B' || type == 'A');
    
if isempty(blocklabel)
  len = 0;
  if doHOG
      width = size(w,2);
      height = size(w,1);
      depth = size(w,3);
      len = len + width*height*depth;
  end
  if doBOF
      len = len + m.K;
  end
  [m, blocklabel] = model_addblock(m, len);
end

% MYMOD
% Common to HOG and BOF
m.filters(j).type = type;
m.filters(j).symmetric = symmetric;
m.filters(j).blocklabel = blocklabel;
m.filters(j).size = [size(w, 1) size(w, 2)];
m.filters(j).flip = flip;

% HOG only
if doHOG    
    m.filters(j).w = w;
end

% BOF only
if doBOF
    m.filters(j).histo = zeros(m.K, 1);
end

% new symbol for terminal associated with filter f
[m, i] = model_addsymbol(m, 'T');
m.symbols(i).filter = j;
m.filters(j).symbol = i;

filterind = j;
symbol = i;
