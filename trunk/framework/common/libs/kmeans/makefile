
all: cpp mex

cpp:
	g++ -O3 -o kmeans_cpp kmeans_cpp.cpp
	
mex:
	/usr/matlab-2009a/bin/mex -O -DMATLAB_MEX kmeans_mex.cpp
	
clean:
	rm -rf kmeans_mex.mexa64 kmeans_cpp *.cpp~ makefile~ *.m~
