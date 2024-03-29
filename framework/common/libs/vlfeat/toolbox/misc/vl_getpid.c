/** @internal
 ** @file    vl_getpid.c
 ** @author  Andrea Vedaldi
 ** @brief   MEX implementation of VL_GETPID()
 **/

/* AUTORIGHTS
Copyright (C) 2007-09 Andrea Vedaldi and Brian Fulkerson

This file is part of VLFeat, available under the terms of the
GNU GPLv2, or (at your option) any later version.
*/

#include <vl/generic.h>

#ifdef VL_OS_WIN
#include <Windows.h>
#else
#include <unistd.h>
#endif

#include <mexutils.h>

void
mexFunction(int nout, mxArray *out[],
            int nin, const mxArray *in[])
{
  double pid ;
#ifdef VL_OS_WIN
  pid = (double) GetCurrentProcessId() ;
#else
  pid = (double) getpid() ;
#endif
  out[0] = uCreateScalar(pid) ;
}
