#include "svm_common.h"

double **dist = NULL;    /* dist[i][j]: 'i' is row index and 'j' is column index */
int dimensionN = 0;
int dimensionM = 0;

void load_data_from_file(char *file);

/*****************************************************************************/
/*                                                                           */
/*                General Kernel with precomputed gram matrix                */
/*                                                                           */
/*****************************************************************************/
double gram_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)                         
{
	if(!dist)
	  load_data_from_file(&kernel_parm->custom[1]);
	  
	if(!a->words->wnum) {
		if(!b->words->wnum) return dist[0][0];
		else           			return dist[0][(int)(b->words->weight)];
	}	else 	{
		if(!b->words->wnum)	return dist[(int)(a->words->weight)][0];
		else								return dist[(int)(a->words->weight)][(int)(b->words->weight)];
	}
}


/*****************************************************************************/
/* Reading input arguments */
void load_data_from_file(char *file)
{
	FILE *fid = fopen(file,"rb");
	fread(&dimensionN, sizeof(int), 1, fid);
	fread(&dimensionM, sizeof(int), 1, fid);	
	dist = (double**)malloc(sizeof(double*)*dimensionN);
	int i;
	for(i=0; i<dimensionN; i++)
	{
		dist[i] = (double*)malloc(sizeof(double)*dimensionM);
		fread(dist[i], sizeof(double), dimensionM, fid);
	}
	fclose(fid);		
}

