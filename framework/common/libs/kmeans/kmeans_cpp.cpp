#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>
#include <time.h>
#include <stdlib.h>
#include <omp.h>

using namespace std;

class kmeans
{
	private:
		float* data;
		int dimension;
		int ndata;

		int ncluster;
		int maxiter;
		int niter;

		float* centers;
		float* assign;

		float* new_centers;
		int* cluster_count;
		int gcd(int,int);
	public:
		// data , dim , ndata , ncluster , maxiter
		kmeans(float*,int,int,int,int);
		void set_out_data(float*,float*);
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

kmeans::kmeans(float* ptr,int value1,int value2,int value3,int value4)
{
	data = ptr;
	dimension = value1;
	ndata = value2;
	ncluster = value3;
	maxiter = value4;
	new_centers = new float[dimension * ncluster];
	cluster_count = new int[ncluster];
}

void kmeans::set_out_data(float* ptr1,float* ptr2)
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
	int index1 = static_cast<int>(ndata*static_cast<float>(rand())/RAND_MAX);
	int index2;
	do{
		index2 = static_cast<int>(ndata*static_cast<float>(rand())/RAND_MAX);
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
		float sum = 0.0;
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
		float sum = 0.0;
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
		cout << "Iteration #" << niter + 1 << endl;
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
		float min_distance;
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
				float value = data[i*dimension + k]-centers[min_index*dimension + k];
				min_distance += value*value;
			}
		}
		for(int j=0;j<ncluster;j++)
		{
			if( j != temp_min_index )
			{
				float c_distance = 0.0;
				for(int k=0;k<dimension;k++)
				{
					float value = data[i*dimension + k] - centers[j*dimension + k];
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
		assign[i] = static_cast<float>(min_index);
		cluster_count[min_index] ++;
		for(int j=0;j<dimension;j++)
			new_centers[min_index*dimension + j] += data[i*dimension + j];

	}
	for(int i=0;i<ncluster;i++)
	{
		if(cluster_count[i] != 0)
			for(int j=0;j<dimension;j++)
				new_centers[i*dimension + j] /= static_cast<float>(cluster_count[i]);
		else
			cout << "Empty Cluster Detected !" << endl;
	}
}

bool kmeans::hasConverged()
{
	float distance = 0.0;
	float epsilon = 1e-3;
	bool abort = false;
	for(int i=0;i<ncluster;i++)
	{
		float cdistance = 0.0;
		for(int j=0;j<dimension;j++)
		{
//			cout << centers[ i* dimension + j ] << "\t" << new_centers[i*dimension +j] << endl;
			float value = centers[i*dimension + j] - new_centers[i*dimension + j];
			cdistance += value*value;
		}
//		cout << cdistance << endl;
		distance += sqrt(cdistance);
		if(distance > epsilon)
		{
			abort = true;
			break;
		}
	}	cout << "Distance: " << distance << endl;
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

void norm2(float *hist, int n)
{
	float s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i]*hist[i];
	s = sqrt(s);
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}
void norm1_with_cutoff(float *hist, int n, float cut_off_threshold)
{
	float s = 1e-10;
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

int main(int argc, char **argv)
{
	if(argc != 5)
	{
		cerr << "Usage: [kmeans] feature-file ncluster maxiter output-file" << endl;
		return 1;
	}

	int dimension = 0;
	int ndata = 0;
	
  //Load data
	FILE *File = fopen(argv[1], "rb");
	
	fread(&dimension, sizeof(int), 1, File);
	fread(&ndata, sizeof(int), 1, File);
	
	float *data = new float[ndata*dimension];
	fread(data, sizeof(float), dimension*ndata, File);
  fclose(File);	
  
	//get size of data matrix
	/*{
		ifstream fin(argv[1]);
		string line, token;

		if(getline(fin, line))
			ndata ++;
		istringstream iss(line);
		while(iss >> token)
			dimension ++;
		while(getline(fin, line))
			ndata ++;
	}

	//Load data
	{
		float *hist = new float[dimension];
		ifstream fin(argv[1]);
		for(int i = 0; i < ndata; i++)
		{
			for(int j = 0; j < dimension; j++)
				fin >> hist[j];

			norm1_with_cutoff(hist, dimension, 0.2);
			norm2(hist, dimension);

			for(int j = 0; j < dimension; j++)
				data[i*dimension + j] = hist[j];
				
			for(int j = 0; j < dimension; j++)
				fin >> data[i*dimension + j];

		}
		delete[] hist;
	}*/
	
//cout << "ndata=" << ndata <<", dimension=" << dimension << endl;	

	int ncluster = atoi(argv[2]); 
	int maxiter = atoi(argv[3]);
	ofstream fout(argv[4]);

	// Seting output arguments
	float *centers = new float[ncluster * dimension];
	float *assign = new float[ndata];
	
	kmeans KMEANS(data,dimension,ndata,ncluster,maxiter);
	KMEANS.set_out_data(centers,assign);

	KMEANS.do_kmeans();
	
	File = fopen(argv[4], "wb+");
	fwrite(centers, sizeof(float), dimension*ncluster, File);
  fclose(File);	

/*	float niter = KMEANS.getNiter();

	for(int i = 0; i < ncluster; i++)
	{
		for(int j = 0; j < dimension; j++)
		{
		//	int index = j * ncluster + i;
			fout << centers[i*dimension + j] << ' ';
		}
		fout << endl;
	}
	
	int *clustersize = new int[ncluster];
	float *meandist = new float[ncluster];
	for(int i = 0; i < ncluster; i++)
	{
		clustersize[i] = 0;
		meandist[i] = 0.0;
	}
	for(int i = 0; i < ndata; i++)
	{
		int ass = (int)assign[i];
		clustersize[ass] ++;
		float dist = 0.0;
		for(int j = 0; j < dimension; j++)
		{
			float value = data[i*dimension + j] - centers[ass*dimension + j];
			dist += value*value;
		}
		meandist[ass] += sqrt(dist);
	}*/
/*	cout << "\nMean Dists:...\n";
	for(int i = 0; i < ncluster; i++)
		cout << meandist[i] / (clustersize[i] + 1e-10) << ' ';
	cout << endl;
*/
	
/*
	cout << "assign: ..." << endl;
	for(int i = 0; i < ndata; i++)
		cout << (int)assign[i] << endl;*/
	return 0;
}
