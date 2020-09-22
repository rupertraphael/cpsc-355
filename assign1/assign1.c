#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>

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

			if(*(numbers+cell) < 0 || *(numbers+cell) > 9) {
				printf("Invalid file. It contains numbers not in the range: 0-9.");

				exit(0);
			}
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

int calculateDocumentSize(int *table, int numberOfColumns, int document) {
	int total = 0;

	int column;
	for(column = 0; column < numberOfColumns; column++) {
		total += *(table + document*numberOfColumns + column);
	}

	// printf("Size: %d", total);

	return total;
}

float calculateFrequency(int *table, int numberOfColumns, int document, int word) {
	float size = calculateDocumentSize(table, numberOfColumns, document);

	if((int) size == 0) {
		return 0;
	}

	float frequency = (*(table + document*numberOfColumns + word)) / size;

	return frequency;
}

// -topRelevantDocs(*table, n) 
void topRelevantDocs(int *table, int numberOfRows, int numberOfColumns, int word, int numberOfDocuments, int sortedRows[numberOfRows]) {
	int row;
	for(row = 0; row < numberOfRows; row++) {
		sortedRows[row] = row;
	}

	bool swapped = false;
	int tempRow;
	
	do {
		swapped = false;

		for(row = 0; row < numberOfRows - 1; row++) {
			if (calculateFrequency(table, numberOfColumns, sortedRows[row], word) < 
				calculateFrequency(table, numberOfColumns, sortedRows[row+1], word)) {
				tempRow = sortedRows[row];
				sortedRows[row] = sortedRows[row+1];
				sortedRows[row + 1] = tempRow;

				swapped = true;
			}
		}
	} while(swapped);

	printf("Top Documents with occurrences for %d:\n", word);

	for(row = 0; row < numberOfDocuments; row++) {
		printf("%d. Doc %d - %d occurences - %f frequency\n", row + 1, sortedRows[row], *(table + sortedRows[row]*numberOfColumns + word), 
			calculateFrequency(table, numberOfColumns, sortedRows[row], word));
	}	
}

// -logToFile()
void logToFile(
	int *table, 
	int numberOfRows, 
	int numberOfColumns, 
	int word, 
	int numTopDocs, 
	int sortedRows[numberOfRows], 
	char cont,
	bool writeTable) {
	FILE *logFile;

	if(writeTable) {
		logFile = fopen("assign1.log", "w");

		int row, column;
		for(row = 0; row < numberOfRows; row++) {
			for(column = 0; column < numberOfColumns; column++) {
				fprintf(logFile, "%-3d", *(table + row*numberOfColumns + column));
			}
			fprintf(logFile, "\n");
		}
	} else {
		logFile = fopen("assign1.log", "a");
	}

	fprintf(logFile, "Enter the index of the word you are searching for: %d\n", word);
	fprintf(logFile, "How many top documents you want to retrieve?  %d\n", numTopDocs);

	fprintf(logFile, "Top Documents with occurrences for %d:\n", word);

	int row, column;
	for(row = 0; row < numberOfRows; row++) {
		fprintf(logFile, "%d. Doc %d - %d occurences - %f frequency\n", row + 1, sortedRows[row], *(table + sortedRows[row]*numberOfColumns + word), 
			calculateFrequency(table, numberOfColumns, sortedRows[row], word));
	}	

	fprintf(logFile, "Do you want to continue? Enter n for no otherwise, to continue. %c", cont);

	fclose(logFile);
}

int main(int argc, char *argv[]) {
	int numberOfRows, numberOfColumns;

	srand(time(0));

	numberOfRows = (int) strtol(argv[1], &argv[1], 10);
	numberOfColumns = (int) strtol(argv[2], &argv[2], 10);

	if(numberOfRows < 5 || numberOfRows > 20 || numberOfColumns < 5 || numberOfColumns > 20) {
		printf("We're sorry but you entered invalid arguments. Number of columns and rows must be between 5-20.");

		exit(0);
	}

	int occurrences[numberOfRows][numberOfColumns];

	FILE *inputFile = NULL;

	// Read file contents.
	if(argc >= 4) {
		inputFile = fopen(argv[3], "r");

		if(inputFile == NULL) {
			printf("We're sorry but the file doesn't exist or is empty.");

			remove(argv[3]);

			exit(0);
		}
	}

	initialize(*occurrences, numberOfRows, numberOfColumns, inputFile);
	fclose(inputFile);
	display(*occurrences, numberOfRows, numberOfColumns);

	int row, column;

	int word, numTopDocs, i = 0;
	char cont = 'y';

	do {
		printf("Enter the index of the word you are searching for: ");
		scanf("%d", &word);
		printf("How many top documents you want to retrieve? ");
		scanf("%d", &numTopDocs);

		int sortedRows[numberOfRows];
		topRelevantDocs(*occurrences, numberOfRows, numberOfColumns, word, numTopDocs, sortedRows);

		printf("Do you want to continue? Enter n for no otherwise, to continue. ");
		scanf(" %c", &cont);

		logToFile(*occurrences, numberOfRows, numberOfColumns, word, numTopDocs, sortedRows, cont, i == 0);
		i++;

	} while(cont != 'n');

    return 0;
}