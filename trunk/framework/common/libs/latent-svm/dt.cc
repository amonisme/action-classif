#include <math.h>
#include <sys/types.h>
#include "mex.h"

/*
 * Generalized distance transforms.
 * We use a simple nlog(n) divide and conquer algorithm instead of the
 * theoretically faster linear method, for no particular reason except
 * that this is a bit simpler and I wanted to test it out.
 *
 * The code is a bit convoluted because dt1d can operate either along
 * a row or column of an array.  
 */

typedef unsigned int int32_t; 
 
//static inline int square(int x) { return x*x; }
static int square(int x) { return x*x; }

// dt helper function
void dt_helper(double *src, double *dst, int *ptr, int step, 
	       int s1, int s2, int d1, int d2, double a, double b) {
 if (d2 >= d1) {
   int d = (d1+d2) >> 1;
   int s = s1;
   int p;
   for (p = s1+1; p <= s2; p++)
     if (src[s*step] - a*square(d-s) - b*(d-s) < 
	 src[p*step] - a*square(d-p) - b*(d-p))
	s = p;
   dst[d*step] = src[s*step] - a*square(d-s) - b*(d-s);
   ptr[d*step] = s;
   dt_helper(src, dst, ptr, step, s1, s, d1, d-1, a, b);
   dt_helper(src, dst, ptr, step, s, s2, d+1, d2, a, b);
 }
}

// dt of 1d array
void dt1d(double *src, double *dst, int *ptr, int step, int n, 
	  double a, double b) {
  dt_helper(src, dst, ptr, step, 0, n-1, 0, n-1, a, b);
}

// matlab entry point
// [M, Ix, Iy] = dt(vals, ax, bx, ay, by)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  int x, y;
  const int *dims;
  double *vals ;
  double ax, bx, ay, by;
  
  mxArray *mxM, *mxIx, *mxIy;
  double *M;
  int32_t *Ix, *Iy;

  double *tmpM;
  int32_t *tmpIx, *tmpIy;
  
  if (nrhs != 5)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 3)
    mexErrMsgTxt("Wrong number of outputs");
  if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS)
    mexErrMsgTxt("Invalid input");

  dims = mxGetDimensions(prhs[0]);
  vals = (double *)mxGetPr(prhs[0]);
  ax = mxGetScalar(prhs[1]);
  bx = mxGetScalar(prhs[2]);
  ay = mxGetScalar(prhs[3]);
  by = mxGetScalar(prhs[4]);
  
  mxM = mxCreateNumericArray(2, dims, mxDOUBLE_CLASS, mxREAL);
  mxIx = mxCreateNumericArray(2, dims, mxINT32_CLASS, mxREAL);
  mxIy = mxCreateNumericArray(2, dims, mxINT32_CLASS, mxREAL);
  M = (double *)mxGetPr(mxM);
  Ix = (int32_t *)mxGetPr(mxIx);
  Iy = (int32_t *)mxGetPr(mxIy);

  tmpM = (double *)mxCalloc(dims[0]*dims[1], sizeof(double));
  tmpIx = (int32_t *)mxCalloc(dims[0]*dims[1], sizeof(int32_t));
  tmpIy = (int32_t *)mxCalloc(dims[0]*dims[1], sizeof(int32_t));

  for (x = 0; x < dims[1]; x++)
    dt1d(vals+x*dims[0], tmpM+x*dims[0], tmpIy+x*dims[0], 1, dims[0], ay, by);

  for (y = 0; y < dims[0]; y++)
    dt1d(tmpM+y, M+y, tmpIx+y, dims[0], dims[1], ax, bx);

  // get argmins and adjust for matlab indexing from 1
  for (x = 0; x < dims[1]; x++) {
    for (y = 0; y < dims[0]; y++) {
      int p = x*dims[0]+y;
      Ix[p] = tmpIx[p]+1;
      Iy[p] = tmpIy[tmpIx[p]*dims[0]+y]+1;
    }
  }

  mxFree(tmpM);
  mxFree(tmpIx);
  mxFree(tmpIy);
  plhs[0] = mxM;
  plhs[1] = mxIx;
  plhs[2] = mxIy;
}
