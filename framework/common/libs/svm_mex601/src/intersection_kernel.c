#include "svm_common.h"

/*****************************************************************************/
/*                                                                           */
/*                           Intersection Kernel                             */
/*                                                                           */
/*****************************************************************************/
double intersection_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)
{
	register double sum=0;
    register WORD *ai,*bj;
    ai=a->words;
    bj=b->words;
    while (ai->wnum && bj->wnum) {
      if(ai->wnum > bj->wnum) 
		bj++;
      else if (ai->wnum < bj->wnum) 
		ai++;
      else {
        if(ai->weight < bj->weight)
        	sum += ai->weight;
       	else
        	sum += bj->weight;
		ai++;
		bj++;
      }
    }
    return sum;
}

