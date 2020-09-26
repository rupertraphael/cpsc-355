#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>

/*
 * randomNum
 * returns a random number between min and max (inclusive)
 */
int randomNum(int min, int max) {
	return (rand() + min) % (max + 1);
}
/*
 * initialize
 * populates a 2D array table with integers given from a well formatted file
 * inputFile or random integers (0 - 9).
 */
void initialize(int *table, int numberOfRows, int numberOfColumns, FILE *inputFile) {
	int numbers[numberOfRows * numberOfColumns];

	int cell;

	// Check if file is empty or does not exist.
	if(inputFile == NULL) {
		// Generate random numbers and store them in a 1D array.
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

	// Use the 1D array numbers and store each of the integers in it in each of table's cells.
	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			*(table + row*numberOfColumns + column) = numbers[cell++];
		}
	}
}

/*
 * display
 * Displays the cells of a 2D array table in numberOfRows rows and
 * numberOfColumns columns.
 */
void display(int *table, int numberOfRows, int numberOfColumns) {
	int row, column;

	// Loop through each table cell and display them with appropriate padding.
	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			printf("%-3d", *(table + row*numberOfColumns + column));
		}
		printf("\n");
	}
}

/*
 * calculateDocumentSize
 * Return the document size of a given document in the table.
 */
int calculateDocumentSize(int *table, int numberOfColumns, int document) {
	int total = 0;

	// Add each integer in the given row (document variable) to total.
	int column;
	for(column = 0; column < numberOfColumns; column++) {
		total += *(table + document*numberOfColumns + column);
	}

	return total;
}

/*
 * calculateFrequency
 * Use calculateDocumentSize to get the document size and use it to divide
 * the occurences of a given word in a document in the table.
 */
float calculateFrequency(int *table, int numberOfColumns, int document, int word) {
	float size = calculateDocumentSize(table, numberOfColumns, document);

	if((int) size == 0) {
		return 0;
	}

	float frequency = (*(table + document*numberOfColumns + word)) / size;

	return frequency;
}

/*
 * topRelevantDocts
 * Use bubble sort to sort documents by each of a given word's frequency in each document.
 * Then, display the given number of top documents.
 */
void topRelevantDocs(int *table, int numberOfRows, int numberOfColumns, int word, int numberOfDocuments, int sortedRows[numberOfRows]) {
	int row;
	// Store the document numbers in an array.
	for(row = 0; row < numberOfRows; row++) {
		sortedRows[row] = row; // still unsorted.
	}

	bool swapped = false;
	int tempRow;
	
	// Sort sorted rows using bubble sort by comparing the frequencies of the
	// given word in each document.
	// This loop ends after the iteration where it has gone through all of 
	// the sorted rows and hasn't swapped any of them. 
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

	// Go through each document in the sorted array and display their document
	// number, the given word's occurence and frequency.
	for(row = 0; row < numberOfDocuments; row++) {
		printf("%2d. Doc %d \t %d occurences \t %f frequency\n", row + 1, sortedRows[row], *(table + sortedRows[row]*numberOfColumns + word), 
			calculateFrequency(table, numberOfColumns, sortedRows[row], word));
	}	
}

/*
 * logToFile
 * Print the documents-words table and other inputs by the user to assign1.log
 */
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

	// Only print the table to the file if specified.
	// Printing the table overwrites the contents of
	// the log file.
	// Otherwise, append all of the other inputs to the log file.
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

	// Here, we append all of the other inputs.
	fprintf(logFile, "Enter the index of the word you are searching for: %d\n", word);
	fprintf(logFile, "How many top documents you want to retrieve?  %d\n", numTopDocs);

	fprintf(logFile, "Top Documents with occurrences for %d:\n", word);

	int row, column;
	for(row = 0; row < numberOfRows; row++) {
		fprintf(logFile, "%2d. Doc %d \t %d occurences \t %f frequency\n", row + 1, sortedRows[row], *(table + sortedRows[row]*numberOfColumns + word), 
			calculateFrequency(table, numberOfColumns, sortedRows[row], word));
	}	

	fprintf(logFile, "Do you want to continue? Enter n for no. Otherwise, enter any character to continue. %c", cont);

	fclose(logFile);
}

int main(int argc, char *argv[]) {
	int numberOfRows, numberOfColumns;


	// Seed the rand().
	srand(time(0));

	// Get the number of rows and columns from the 
	// command line arguments.
	numberOfRows = (int) strtol(argv[1], &argv[1], 10);
	numberOfColumns = (int) strtol(argv[2], &argv[2], 10);

	// Ensure that the number of rows and columns are between 5-20 inclusive.
	if(numberOfRows < 5 || numberOfRows > 20 || numberOfColumns < 5 || numberOfColumns > 20) {
		printf("We're sorry but you entered invalid arguments. Number of columns and rows must be between 5-20.");

		exit(0);
	}

	int occurrences[numberOfRows][numberOfColumns];

	FILE *inputFile = NULL;

	// Open the file only when
	// it is given and
	// exit when it is empty or does not exist.
	if(argc >= 4) {
		inputFile = fopen(argv[3], "r");

		if(inputFile == NULL) {
			printf("We're sorry but the file doesn't exist or is empty.");
			
			fclose(argv[3]);
			remove(argv[3]);

			exit(0);
		}
	}

	initialize(*occurrences, numberOfRows, numberOfColumns, inputFile);

	if(inputFile != NULL) {
		fclose(inputFile);
	}	

	display(*occurrences, numberOfRows, numberOfColumns);

	int row, column;

	int word, numTopDocs, i = 0;
	char cont = 'y';

	// Continuously ask for a word to search for
	// and the number of top documents to retrieve.
	do {
		printf("Enter the index of the word you are searching for: ");
		scanf("%d", &word);

		// Ensure word exists in the document.
		if(word >= numberOfColumns) {
			printf("We're sorry but that word does not exist.\n");
			printf("Please try again.\n");

			continue;
		}

		printf("How many top documents you want to retrieve? ");
		scanf("%d", &numTopDocs);


		// Ensure top documents to retrieve does not exceed actual number
		// of documents.
		if(numTopDocs > numberOfRows) {
			printf("You're retrieving more documents than there are documents.");
			printf("\nRetrieving %d doc(s).", numberOfRows);

			numTopDocs = numberOfRows;
		}

		int sortedRows[numberOfRows];
		topRelevantDocs(*occurrences, numberOfRows, numberOfColumns, word, numTopDocs, sortedRows);

		printf("Do you want to continue? Enter n for no. Otherwise, enter any character to continue. ");
		scanf(" %c", &cont);

		logToFile(*occurrences, numberOfRows, numberOfColumns, word, numTopDocs, sortedRows, cont, i == 0);
		i++;

	} while(cont != 'n'); // Search loop ends when user enters 'n'.

    return 0;
}
