function [hog_blocks,num_block_h,num_block_w]=poselet_image2features(img)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% image2features: Evaluates HOG features in a dense grid over the input
%%% image (at a scale 1x1 only) and returns the associated feature vectors
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global config;
global ts;

DEBUG=0;

cell_size = config.HOG_CELL_DIMS./config.NUM_HOG_BINS;
block_size = config.PATCH_DIMS(2:-1:1)./cell_size(1:2);
hog_block_size = block_size-1;

% Compute the HOG cells
hog_c = poselet_compute_hog(img);

[H,W,hog_hog_len] = size(hog_c);

num_blocks = max(0,[W H] - hog_block_size + 1);
num_block_w = num_blocks(1);
num_block_h = num_blocks(2);

if ~isempty(ts) ts=ts.end_stage(); end

block_hog_len = hog_hog_len*prod(hog_block_size);

% String them into blocks
hog_blocks = zeros(prod(num_blocks),block_hog_len,'single');
if prod(num_blocks)>0
    
    for x=0:hog_block_size(1)-1
       for y=0:hog_block_size(2)-1
            hog_blocks(:,(x*hog_block_size(2)+y)*hog_hog_len+(1:hog_hog_len)) = reshape(hog_c(y+(1:num_blocks(2)),x+(1:num_blocks(1)),:),[prod(num_blocks) hog_hog_len]);
       end
    end

    % Reference implementation. Slow but more readable version that must
    % produce the same result as the real one
    if DEBUG>0
        hog_blocks1 = zeros(prod(num_blocks),block_hog_len,'single');
        for x=0:num_blocks(1)-1
            for y=0:num_blocks(2)-1
              hog_features=[];
              for xx=0:hog_block_size(1)-1
                   for yy=0:hog_block_size(2)-1
                        hog_features = [hog_features reshape(hog_c(y+yy+1,x+xx+1,:),[1 hog_hog_len])]; %#ok<AGROW>
                   end
              end
            end
        end
        assert(isequal(hog_blocks, hog_blocks1));
    end
    
end
if ~isempty(ts) ts=ts.end_stage('hog2blocks'); end

