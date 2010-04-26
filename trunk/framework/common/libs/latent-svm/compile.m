!/usr/matlab-2009a/bin/mex -O resize.cc
!/usr/matlab-2009a/bin/mex -O dt.cc
!/usr/matlab-2009a/bin/mex -O features.cc

% use one of the following depending on your setup
% 1 is fastest, 3 is slowest 

% 1) multithreaded convolution using blas
%!/usr/matlab-2009a/bin/mex -O fconvblas.cc -lmwblas -o fconv
% 2) mulththreaded convolution without blas
!/usr/matlab-2009a/bin/mex -O fconvMT.cc -o fconv
% 3) basic convolution, very compatible
%!/usr/matlab-2009a/bin/mex -O fconv.cc -o fconv
