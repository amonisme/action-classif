/************************************************************************/
/*                                                                      */
/*   kernel.h                                                           */
/*                                                                      */
/*   User defined kernel function. Feel free to plug in your own.       */
/*                                                                      */
/*   Copyright: Thorsten Joachims                                       */
/*   Date: 16.12.97                                                     */
/*                                                                      */
/************************************************************************/

/* KERNEL_PARM is defined in svm_common.h The field 'custom' is reserved for */
/* parameters of the user defined kernel. You can also access and use */
/* the parameters of the other kernels. Just replace the line 
             return((double)(1.0)); 
   with your own kernel. */

  /* Example: The following computes the polynomial kernel. sprod_ss
              computes the inner product between two sparse vectors. 

      return((CFLOAT)pow(kernel_parm->coef_lin*sprod_ss(a->words,b->words)
             +kernel_parm->coef_const,(double)kernel_parm->poly_degree)); 
  */

/* If you are implementing a kernel that is not based on a
   feature/value representation, you might want to make use of the
   field "userdefined" in SVECTOR. By default, this field will contain
   whatever string you put behind a # sign in the example file. So, if
   a line in your training file looks like

   -1 1:3 5:6 #abcdefg

   then the SVECTOR field "words" will contain the vector 1:3 5:6, and
   "userdefined" will contain the string "abcdefg". */
   
#ifndef KERNELH
#define KERNELH

double gram_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b);
double chi2_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b);
double intersection_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b);

/*****************************************************************************/
/*                                                                           */
/*                               Custom Kernel                               */
/*                                                                           */
/*****************************************************************************/
double custom_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b) 
     /* plug in you favorite kernel */                          
{
	switch(kernel_parm->custom[0])
	{
		case '0': return gram_kernel(kernel_parm, a, b);	
		case '1': return chi2_kernel(kernel_parm, a, b);
		case '2': return intersection_kernel(kernel_parm, a, b);
		default:
		#ifdef MATLAB_MEX
			mexErrMsgTxt("Unknown personnal kernel function!");
		#else
			printf("Error: Unknown personnal kernel function!\n"); 
			exit(1);
		#endif
	}
}

#endif
