function pyra = my_featpyramid(im, model, padx, pady)

% pyra = featpyramid(im, model, padx, pady);
% Compute feature pyramid.
%
% pyra.feat{i} is the i-th level of the feature pyramid.
% pyra.scales{i} is the scaling factor used for the i-th level.
% pyra.feat{i+interval} is computed at exactly half the resolution of feat{i}.
% first octave halucinates higher resolution data.
% padx,pady optionally pads each level of the feature pyramid

if nargin < 3
  [padx, pady] = getpadding(model);
end

sbin = model.sbin;
interval = model.interval;
sc = 2^(1/interval);
imsize = im.size;
max_scale = 1 + floor(log(min(imsize)/(5*sbin))/log(sc));
pyra.feat = cell(max_scale + interval, 1);
pyra.scales = zeros(max_scale + interval, 1);
pyra.imsize = imsize;

% our resize function wants floating point values
for i = 1:interval
  scaled = im;
  scaled.size        = ceil(scaled.size        * 1/sc^(i-1));  
  scaled.feat(:,1:2) = ceil(scaled.feat(:,1:2) * 1/sc^(i-1));  
  % "first" 2x interval
  pyra.feat{i} = integral_histo(scaled, model.K, model.sbin/2);
  pyra.scales(i) = 2/sc^(i-1);
  % "second" 2x interval
  pyra.feat{i+interval} = downsample_ihisto(pyra.feat{i});
  pyra.scales(i+interval) = 1/sc^(i-1);
  % remaining interals
  for j = i+interval:interval:max_scale    
    pyra.feat{j+interval} = downsample_ihisto(pyra.feat{j});
    pyra.scales(j+interval) = 0.5 * pyra.scales(j);
  end
end

for i = 1:length(pyra.feat)
  pyra.feat{i} = padarray(pyra.feat{i}, [pady padx 0], 0);
  % write boundary occlusion feature
  pyra.feat{i}(1:pady, :, model.K) = 1;
  pyra.feat{i}((end-pady+1):end, :, model.K) = 1;
  pyra.feat{i}(:, 1:padx, model.K) = 1;
  pyra.feat{i}(:, (end-padx+1):end, model.K) = 1;
end
pyra.padx = padx;
pyra.pady = pady;
