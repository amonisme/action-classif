#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "mex.h"

#include "load_kernel.h"

double **K = NULL;    /* K[i][j]: 'i' is row index and 'j' is column index */
int dimensionN = 0;
int dimensionM = 0;

/*****************************************************************************/
/* Reading input arguments */
void load_kernel_from_file(char *file)
{
	FILE *fid = fopen(file,"rb");
	printf("%s\n", file);
	fread(&dimensionN, sizeof(int), 1, fid);
	fread(&dimensionM, sizeof(int), 1, fid);	
	K = (double**)malloc(sizeof(double*)*dimensionN);
	printf("%d %d %p\n", dimensionN, dimensionM, K);
	int i;
	for(i=0; i<dimensionN; i++)
	{
		K[i] = (double*)malloc(sizeof(double)*dimensionM);
		fread(K[i], sizeof(double), dimensionM, fid);
	}
	fclose(fid);		
}

int is_kernel_loaded()
{
	return K != NULL;
}

/*****************************************************************************/
/* K(i,j) */
double kernel_value(int i, int j)
{
	return K[i][j];
}

/*****************************************************************************/
/* Frees the memory */
void free_kernel()
{
	if(K)
	{
		int i;
		for(i=0; i<dimensionN; i++)
			free(K[i]);
		free(K);
	}
}
