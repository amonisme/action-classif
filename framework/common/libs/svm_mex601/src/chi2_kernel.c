#include "svm_common.h"

double chi2_distance(SVECTOR *a, SVECTOR *b);

/*****************************************************************************/
/*                                                                           */
/*                              Chi2 Kernel                                  */
/*                                                                           */
/*****************************************************************************/
double chi2_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)                         
{
	return exp(-kernel_parm->rbf_gamma*chi2_distance(a,b));
}

/*****************************************************************************/
/*****************************************************************************/
/* Chi2 Distance
*/
double chi2_distance(SVECTOR *a, SVECTOR *b)
{
  register double sum=0;
  register WORD *ai,*bj;
  register double num;
	register double denom;
  ai=a->words;
  bj=b->words;
  while (ai->wnum && bj->wnum) {
    if(ai->wnum > bj->wnum) {
	sum += bj->weight;
	bj++;
    }
    else if (ai->wnum < bj->wnum) {
	sum += ai->weight;
	ai++;
    }
    else {
	num   = ai->weight - bj->weight;
	denom = ai->weight + bj->weight;
	if(denom)
		sum += num*num/denom;
	ai++;
	bj++;
    }
  }
	while(ai->wnum)
	{
		sum += ai->weight;
		ai++;	
	}
	while(bj->wnum)
	{
		sum += bj->weight;
		bj++;	
	}	
  return sum*2.;
}

