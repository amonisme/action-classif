function [dets, boxes, info] = imgdetect(Ipath, model, thresh, bbox, overlap)

% Wrapper that computes detections in the input image.
%
% input    input image
% model    object model
% thresh   detection score threshold
% bbox     ground truth bounding box
% overlap  overlap requirement

input = color(imread(Ipath));

% MYMOD
feat = SignatureAPI.compute_features(model.detector, Ipath);
descr = SignatureAPI.compute_descriptors(model.detector, model.descriptor, Ipath, feat);
d = dist2(model.centers, descr);
m = (d == repmat(min(d), size(d,1), 1));
n_descr = size(descr, 1);
for j=1:n_descr
    a = find(m(:,j), 1);
    % X Y Scale Angle Type
    feat(j,5) = a;
end

% get the feature pyramid
info = imfinfo(Ipath);    
pyra = featpyramid(input, struct('size', [info.Height info.Width], 'feat', feat), model);

if nargin < 4
  bbox = [];
end

if nargin < 5
  overlap = 0;
end

[dets, boxes, info] = gdetect(pyra, model, thresh, bbox, overlap);
