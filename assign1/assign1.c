#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// randomNum(m,n); m and n are the lower and upper bounds for the random number. You can use the C library function rand(). 
int randomNum(int min, int max) {
	return (rand() + min) % (max + 1);
}
// initialize(*table) 
void initialize(int *table, int numberOfRows, int numberOfColumns, FILE *inputFile) {
	int numbers[numberOfRows * numberOfColumns];

	int cell;

	if(inputFile == NULL) {
		// Generate random numbers
		for(cell = 0; cell < numberOfRows * numberOfColumns; cell++) {
			*(numbers + cell) = randomNum(0, 9);
		}
	} else {
		// Read file contents and save to 1D array.
		for(cell = 0; cell < numberOfRows * numberOfColumns; cell++) {
			fscanf(inputFile, "%d", numbers+cell);
		}
	}

	int row, column;
	cell = 0;

	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			*(table + row*numberOfColumns + column) = numbers[cell++];
		}
	}
}
// -display(*table) 
void display(int *table, int numberOfRows, int numberOfColumns) {
	int row, column;

	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			printf("%-3d", *(table + row*numberOfColumns + column));
		}
		printf("\n");
	}
}
// -topRelevantDocs(*table, n) 
// -logToFile()

int main(int argc, char *argv[]) {
	int numberOfRows, numberOfColumns;

	srand(time(0));

	numberOfRows = (int) strtol(argv[1], &argv[1], 10);
	numberOfColumns = (int) strtol(argv[2], &argv[2], 10);

	int occurrences[numberOfRows][numberOfColumns];

	FILE *inputFile = NULL;

	// Read file contents.
	if(argc == 4) {
		inputFile = fopen(argv[3], "r");
	}

	initialize(*occurrences, numberOfRows, numberOfColumns, inputFile);
	fclose(inputFile);
	display(*occurrences, numberOfRows, numberOfColumns);

    return 0;
}