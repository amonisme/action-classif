function pyra = my_featpyramid(imHOG, imBOF, model, padx, pady)

% pyra = my_featpyramid(imHOG, imBOF, model, padx, pady);
% Compute feature pyramid.
%
% pyra.feat{i} is the i-th level of the feature pyramid.
% pyra.scales{i} is the scaling factor used for the i-th level.
% pyra.feat{i+interval} is computed at exactly half the resolution of feat{i}.
% first octave halucinates higher resolution data.
% padx,pady optionally pads each level of the feature pyramid

if nargin < 4
  [padx, pady] = getpadding(model);
end

sbin = model.sbin;
interval = model.interval;
sc = 2^(1/interval);
imsize = [size(imHOG, 1) size(imHOG, 2)];
max_scale = 1 + floor(log(min(imsize)/(5*sbin))/log(sc));
pyra.feat = cell(max_scale + interval, 1);
pyra.scales = zeros(max_scale + interval, 1);
pyra.imsize = imsize;

% our resize function wants floating point values
imHOG = double(imHOG);
imBOF.feat(:,1) = imBOF.feat(:,1) / imBOF.size(1);
imBOF.feat(:,2) = imBOF.feat(:,2) / imBOF.size(2);
for i = 1:interval
  cur_sc = 1/sc^(i-1);  
  scaledHOG = resize(imHOG, cur_sc);  
  scaledBOF = imBOF;
  s = size(scaledHOG);
  scaledBOF.size      = s(1:2);
  scaledBOF.feat(:,1) = ceil(imBOF.feat(:,1) * scaledBOF.size(1)) - 1;  % between 0 and maxsize - 1   
  scaledBOF.feat(:,2) = ceil(imBOF.feat(:,2) * scaledBOF.size(2)) - 1;   
  % "first" 2x interval
  pyra.feat {i} = features(scaledHOG, sbin/2);
  histo = my_integral_histo(scaledBOF, model.K, model.sbin/2);
  pyra.histo{i} = my_crop_histo(histo);

  pyra.scales(i) = 2 * cur_sc;
  % "second" 2x interval
  pyra.feat  {i+interval} = features(scaledHOG, sbin);
  histo = my_downsample_ihisto(histo, size(scaledHOG), model.sbin);
  pyra.histo {i+interval} = my_crop_histo(histo);
  
  pyra.scales(i+interval) = cur_sc;
  % remaining interals
  for j = i+interval:interval:max_scale
    scaledHOG = resize(scaledHOG, 0.5);
    pyra.feat  {j+interval} = features(scaledHOG, sbin);
    scaledBOF.size      = size(scaledHOG);  
    s = size(scaledHOG);
    scaledBOF.size      = s(1:2);    
    scaledBOF.feat(:,1) = ceil(imBOF.feat(:,1) * scaledBOF.size(1));     
    scaledBOF.feat(:,2) = ceil(imBOF.feat(:,2) * scaledBOF.size(2));     
    histo = my_downsample_ihisto(histo, size(scaledHOG), model.sbin);
    pyra.histo {j+interval} = my_crop_histo(histo);
    pyra.scales(j+interval) = 0.5 * pyra.scales(j);
  end
end

for i = 1:length(pyra.feat)
  % add 1 to padding because feature generation deletes a 1-cell
  % wide border around the feature map
  pyra.feat{i} = padarray(pyra.feat{i}, [pady+1 padx+1 0], 0);  
  % write boundary occlusion feature
  pyra.feat{i}(1:pady+1, :, 32) = 1;
  pyra.feat{i}(end-pady:end, :, 32) = 1;
  pyra.feat{i}(:, 1:padx+1, 32) = 1;
  pyra.feat{i}(:, end-padx:end, 32) = 1;
  
  %pyra.histo{i} = padarray(pyra.histo{i}, [pady+1 padx+1 0], 0);
  pyra.histo{i} = padarray(pyra.histo{i}, [pady+1 padx+1 0], 0, 'pre');
  pyra.histo{i} = padarray(pyra.histo{i}, [pady+1 padx+1 0], 'replicate', 'post');    
end
pyra.padx = padx;
pyra.pady = pady;
