#include <stdio.h>
#include <stdlib.h>
#include "svm_common.h"
#include "precomputed.h"

#ifdef MATLAB_MEX             /* include MATLAB headers as necessary */
#include "mex.h"
#include "matrix.h"
#include "mexcommon.h"
#endif 

double **dist = NULL;
int dimension = 0;

/*****************************************************************************/
/* Reading input arguments */
void load_data_from_file(char *file)
{
	printf("load\n");
	FILE *fid = fopen(file,"rb");
	fread(&dimension, 4, 1, fid);
	dist = (double**)malloc(sizeof(double*)*dimension);
	int i;
	for(i=0; i<dimension; i++)
	{
		dist[i] = (double*)malloc(sizeof(double)*dimension);
		fread(dist[i], sizeof(double), dimension, fid);
	}
	fclose(fid);		
}

/*****************************************************************************/
double get_precomputed_dist(SVECTOR *a, SVECTOR *b, char *file)
{
	if(!dist)
	  load_data_from_file(file);

	if(!a->words->wnum)  
		if(!b->words->wnum)
			return 0.;
		else   /* distance from b to origin on diagonal */
			return dist[(int)(b->words->weight)][(int)(b->words->weight)];
	else if(!b->words->wnum)   /* distance from a to origin on diagonal */
		return dist[(int)(a->words->weight)][(int)(a->words->weight)];
	else
		return dist[(int)(a->words->weight)][(int)(b->words->weight)];
}
/*****************************************************************************/
