#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>
#include <time.h>
#include <stdlib.h>
#include <mex.h>

using namespace std;

class kmeans
{
	private:
		double* data;
		int dimension;
		int ndata;

		int ncluster;
		int maxiter;
		int niter;

		double* centers;
		double* assign;

		double* new_centers;
		int* cluster_count;
		int gcd(int,int);
	public:
		// data , dim , ndata , ncluster , maxiter
		kmeans(double*,int,int,int,int);
		void set_out_data(double*,double*);
		int getNiter();

		void initialize();

		void do_kmeans();

		void clear_new_centers();
		void find_new_centers();
		bool hasConverged();

		bool hasEmptyFeatureVector();
		bool hasEmptyClusterCenter();
};

int kmeans::gcd(int num1,int num2)
{
	if(num2 == 0)
		return num1;
	else
	{
		int q = num1/num2;
		return gcd(num2,num1 - q*num2);
	}
}

kmeans::kmeans(double* ptr,int value1,int value2,int value3,int value4)
{
	data = ptr;
	dimension = value1;
	ndata = value2;
	ncluster = value3;
	maxiter = value4;
	new_centers = new double[dimension * ncluster];
	cluster_count = new int[ncluster];

}

void kmeans::set_out_data(double* ptr1,double* ptr2)
{
	centers = ptr1;
	assign = ptr2;
	for(int i=0;i<ndata;i++)
		assign[i] = -1;
}

void kmeans::initialize()
{
//	if(hasEmptyFeatureVector())
//		cout << "Empty feature vector detected!" << endl;
	srand(time(NULL));
	int index1 = static_cast<int>(ndata*static_cast<double>(rand())/RAND_MAX);
	int index2;
	do{
		index2 = static_cast<int>(ndata*static_cast<double>(rand())/RAND_MAX);
	}while(gcd(index1,index2) != 1);
	for(int i=0;i<ncluster;i++)
	{
		for(int j=0;j<dimension;j++)
		{
			centers[i*dimension + j] = data[index1*dimension + j];
		}
		index1 = index2 + index1;
		if(index1 >= ndata)
			index1 -= ndata;
	}
//	if(hasEmptyClusterCenter())
//		cout << "Empty initial cluster center detected!" << endl;
}

bool kmeans::hasEmptyFeatureVector()
{
	bool return_value = false;
	for(int i=0;i<ndata;i++)
	{
		double sum = 0.0;
		for(int j=0;j<dimension;j++)
		{
			sum += centers[i * dimension + j];
		}
		if(sum == 0)
		{
			return_value = true;
			break;
		}
	}
	return return_value;
}

bool kmeans::hasEmptyClusterCenter()
{
	bool return_value = false;
	for(int i=0;i<ncluster;i++)
	{
		double sum = 0.0;
		for(int j=0;j<dimension;j++)
		{
			sum += centers[i * dimension + j];
		}
		if(sum == 0)
		{
			return_value = true;
			break;
		}
	}
	return return_value;
}

void kmeans::do_kmeans()
{
	initialize();
	niter = 0;
	do{
		clear_new_centers();
		find_new_centers();
		niter++;
	}while(!hasConverged() && niter < maxiter);
}

void kmeans::clear_new_centers()
{
	for(int i=0;i<dimension*ncluster;i++)
		new_centers[i] = 0.0;
	for(int i=0;i<ncluster;i++)
		cluster_count[i] = 0;
}

void kmeans::find_new_centers()
{
	/*
	   To make the code work more efficient we assume that for every point we assume that
	   the closest distance is when it is assigned to it's previouse cluster center man fe
   	*/
	for(int i=0;i<ndata;i++)
	{
		double min_distance;
		int min_index;
		int temp_min_index;
		if(assign[i] == -1)
		{
			min_distance = 10e10;
			min_index = -1;
			temp_min_index = -1;
		}
		else
		{
			min_index = static_cast<int>(assign[i]);
			if(min_index < 0 || min_index >= ncluster)
				cout << "Error : " << min_index << endl;
			temp_min_index = min_index;
			min_distance = 0.0;
			for(int k=0;k<dimension;k++)
			{
				double value = data[i*dimension + k]-centers[min_index*dimension + k];
				min_distance += value*value;
			}
		}
		for(int j=0;j<ncluster;j++)
		{
			if( j != temp_min_index )
			{
				double c_distance = 0.0;
				for(int k=0;k<dimension;k++)
				{
					double value = data[i*dimension + k] - centers[j*dimension + k];
					c_distance += value*value;
					if(c_distance >= min_distance)
						break;
				}
				if(c_distance < min_distance)
				{
					min_distance = c_distance;
					min_index = j;
				}
			}
		}
		assign[i] = static_cast<double>(min_index);
		cluster_count[min_index] ++;
		for(int j=0;j<dimension;j++)
			new_centers[min_index*dimension + j] += data[i*dimension + j];

	}
	for(int i=0;i<ncluster;i++)
	{
		if(cluster_count[i] != 0)
		{
			for(int j=0;j<dimension;j++)
			{
				new_centers[i*dimension + j] /= static_cast<double>(cluster_count[i]);
//				cluster_count[i] = 0;
			}
		}
		else
		{
			//cout << "Empty Cluster Detected !" << endl;
		}
	}
}

bool kmeans::hasConverged()
{
	double distance = 0.0;
	double epsilon = 1e-3;
	bool abort = false;
	for(int i=0;i<ncluster;i++)
	{
		double cdistance = 0.0;
		for(int j=0;j<dimension;j++)
		{
//			cout << centers[ i* dimension + j ] << "\t" << new_centers[i*dimension +j] << endl;
			double value = centers[i*dimension + j] - new_centers[i*dimension + j];
			cdistance += value*value;
		}
//		cout << cdistance << endl;
		distance += sqrt(cdistance);
		if(distance > epsilon)
		{
			abort = true;
			break;
		}
	}
//	cout << distance << endl;
	if(!abort)
		return true;
	else
	{
		for(int i=0;i<ncluster*dimension;i++)
		{
			centers[i] = new_centers[i];
			new_centers[i] = 0;
		}
		return false;
	}

}

int kmeans::getNiter()
{
	return niter;
}

void norm2(double *hist, int n)
{
	double s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i]*hist[i];
	s = sqrt(s);
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}
void norm1_with_cutoff(double *hist, int n, double cut_off_threshold)
{
	double s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i];
	for(int i = 0; i < n; i++)
		hist[i] /= s;

	//Cut-off
	for(int i = 0; i < n; i++)
		if(hist[i] > cut_off_threshold)
			hist[i] = cut_off_threshold;

	//re-normalization
	s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i];
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}

void mexFunction(int nlhs,mxArray* plhs[],int nrhs,const mxArray* prhs[])
{
	// Reading input arguments
	double* data = mxGetPr(prhs[0]);

	int dimension = static_cast<int>(mxGetM(prhs[0]));
	int ndata = static_cast<int>(mxGetN(prhs[0]));

	int ncluster = static_cast<int>(mxGetScalar(prhs[1]));
	int maxiter = static_cast<int>(mxGetScalar(prhs[2]));

	// Seting output arguments

	plhs[0] = mxCreateDoubleMatrix(dimension,ncluster,mxREAL);
	double* centers = mxGetPr(plhs[0]);
	plhs[1] = mxCreateDoubleMatrix(1,ndata,mxREAL);
	double* assign = mxGetPr(plhs[1]);
	plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
	double* niter = mxGetPr(plhs[2]);

	
	kmeans KMEANS(data,dimension,ndata,ncluster,maxiter);
	KMEANS.set_out_data(centers,assign);
	KMEANS.do_kmeans();

	int *clustersize = new int[ncluster];
	double *meandist = new double[ncluster];
	for(int i = 0; i < ncluster; i++)
	{
		clustersize[i] = 0;
		meandist[i] = 0.0;
	}
	for(int i = 0; i < ndata; i++)
	{
		int ass = (int)assign[i];
		clustersize[ass] ++;
		double dist = 0.0;
		for(int j = 0; j < dimension; j++)
		{
			double value = data[i*dimension + j] - centers[ass*dimension + j];
			dist += value*value;
		}
		meandist[ass] += sqrt(dist);
	}
}
