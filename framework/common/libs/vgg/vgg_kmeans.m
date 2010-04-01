function [CX, sse] = vgg_kmeans(X, nclus, maxiters, mindelta, verbose)

% VGG_KMEANS    initialize K-means clustering
%               [CX, sse] = vgg_kmeans(X, nclus, optname, optval, ...)
%
%               - X: input points (one per column)
%               - nclus: number of clusters
%               - opts (defaults):
%                    maxiters (inf): maxmimum number of iterations
%                    mindelta (eps): minimum change in SSE per iteration
%                       verbose (1): 1=print progress
%
%               - CX: cluster centers
%               - sse: SSE

% Author: Mark Everingham <me@robots.ox.ac.uk>
% Date: 13 Jan 03

if nargin < 3
    maxiters = inf;
end
if nargin < 4
    mindelta = eps;
end
if nargin < 5
    verbose = 0;
end

opts = struct('maxiters', maxiters, 'mindelta', mindelta, 'verbose', verbose);

perm=randperm(size(X,2));
CX=X(:,perm(1:nclus));

sse0 = inf;
iter = 0;
while iter < opts.maxiters

    tic;    
    [CX, sse] = vgg_kmiter(X, CX);    
    t=toc;

    if opts.verbose
        fprintf('iter %d: sse = %g (%g secs)\n', iter, sse, t)
    end
    
    if sse0-sse < opts.mindelta
        break
    end

    sse0=sse;
    iter=iter+1;
        
end

