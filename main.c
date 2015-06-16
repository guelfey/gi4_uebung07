#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <pthread.h>
#include "init_matrix.h"

#define MATRIX_SIZE (1024)
#define NTHREADS (2)

double **A;
double *b;
double *X;
double *X_old;
double *temp;

struct thread_arg {
	// A, X and b are global
	int start, end;
};

extern double vect_dist_sse(double *v1, double *v2, int N);

// Returns the euclidic distance of the given vectors.
double vect_dist(double *v1, double *v2, int N) {
	double sum = 0.0;
	int i;

	for (i = 0; i < N; i++)
		sum += (v1[i] - v2[i]) * (v1[i] - v2[i]);
	return sqrt(sum);
}

void *thread_func(void* void_arg) {
	struct thread_arg arg = *((struct thread_arg*) void_arg);
	double sum;
	int i, j;
	for (i = arg.start; i < arg.end; i++) {
		sum = 0.0;
		for (j = 0; j < MATRIX_SIZE; j++) {
			if (i != j)
				sum += A[i][j]*X_old[j];
		}
		X[i] = (b[i] - sum) / A[i][i];
	}
	return NULL;
}

int main(int argc, char **argv)
{
	unsigned int i, j;
	unsigned int iterations = 0;
	double error, norm, max = 0.0;
	double sum, epsilon;
	struct timeval start, end;
	pthread_t threads[NTHREADS];
	struct thread_arg thread_args[NTHREADS];

	printf("\nInitialize system of linear equations...\n");
	/* allocate memory for the system of linear equations */
	init_matrix(&A, &b, MATRIX_SIZE);
	X = (double *)malloc(sizeof(double) * MATRIX_SIZE);
	X_old = (double *)malloc(sizeof(double) * MATRIX_SIZE);

	/* a "random" solution vector */
	for (i = 0; i < MATRIX_SIZE; i++) {
		X[i] = ((double)rand()) / ((double)RAND_MAX) * 10.0;
		X_old[i] = 0.0;
	}



	printf("Start Jacobi method...\n");

	gettimeofday(&start, NULL);

	epsilon = sqrt(1e-7 * MATRIX_SIZE);
	while (1) {
		// create threads
		for (i = 0; i < NTHREADS; i++) {
			thread_args[i].start = MATRIX_SIZE/NTHREADS*i;
			thread_args[i].end = MATRIX_SIZE/NTHREADS*(i+1);
			pthread_create(&threads[i], NULL, thread_func, &thread_args[i]);
		}
		for (i = 0; i < NTHREADS; i++)
			pthread_join(threads[i], NULL);
		// wait for threads to finish
		iterations++;
		norm = vect_dist_sse(X, X_old, MATRIX_SIZE);
		printf("error: %f\n", norm);
		if (norm < epsilon)
			break;
		for (i = 0; i < MATRIX_SIZE; i++)
			X_old[i] = X[i];
	}

	gettimeofday(&end, NULL);

	if (MATRIX_SIZE < 16) {
		printf("Print the solution...\n");
		/* print solution */
		for (i = 0; i < MATRIX_SIZE; i++) {
			for (j = 0; j < MATRIX_SIZE; j++)
				printf("%8.2f\t", A[i][j]);
			printf("*\t%8.2f\t=\t%8.2f\n", X[i], b[i]);
		}
	}

	printf("Check the result...\n");
	/* 
	 * check the result 
	 * X[i] have to be 1
	 */
	for (i = 0; i < MATRIX_SIZE; i++) {
		error = fabs(X[i] - 1.0f);

		if (max < error)
			max = error;
		if (error > 0.01f)
			printf("Result is on position %d wrong (%f != 1.0)\n",
			       i, X[i]);
	}
	printf("maximal error is %f\n", max);

	printf("\nmatrix size: %d x %d\n", MATRIX_SIZE, MATRIX_SIZE);
	printf("number of iterations: %d\n", iterations);
	printf("Time : %lf sec\n",
	       (double)(end.tv_sec - start.tv_sec) + (double)(end.tv_usec -
							      start.tv_usec) /
	       1000000.0);

	/* frees the allocated memory */
	free(X_old);
	free(X);
	clean_matrix(&A);
	clean_vector(&b);

	return 0;
}
