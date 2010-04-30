#include "svm_common.h"
#include "load_kernel.h"

/*****************************************************************************/
/*                                                                           */
/*                General Kernel with precomputed gram matrix                */
/*                                                                           */
/*****************************************************************************/
double gram_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)                         
{
	if(!is_kernel_loaded())
	  load_kernel_from_file(&kernel_parm->custom[1]);
	  
	if(!a->words->wnum) {
		if(!b->words->wnum) return kernel_value(0, 0);
		else           			return kernel_value(0, (int)(b->words->weight));
	}	else 	{
		if(!b->words->wnum)	return kernel_value((int)(a->words->weight), 0);
		
		else								return kernel_value((int)(a->words->weight), (int)(b->words->weight));
	}
}



