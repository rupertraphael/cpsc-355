#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Source: https://stackoverflow.com/questions/3585846/color-text-in-terminal-applications-in-unix
#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"

/*
 * randomNum
 * returns a random number between min and max (inclusive)
 * only correct if max = 2^n - 1 where n is an integer.
 * multiplies the random number by -1 if negative is true.
 */
float randomNum(int min, int max, bool negative) {
	float num; 

	// Generate random number until it is in bounds.
	do {
		num = ((rand() + min) & (max)) 
			+ ((float)rand() / (float)(RAND_MAX)); // Add fraction to whole number.
	} while(num <= min || num > max);

	if(negative) {
		num *= -1;
	}

	return num;
}

void initializeGame(float *board, bool *covered, int numberOfRows, int numberOfColumns) {
	int row, column;

	int min = 0,max = 15;

	int percentageOfPowerups = 20, percentageOfNegatives = 40;
	int maxNumberOfPowerups, maxNumberOfNegatives;
	int numberOfPowerups = 0, numberOfNegatives = 0;

	maxNumberOfPowerups = (int)(numberOfRows * numberOfColumns * percentageOfPowerups / 100);
	maxNumberOfNegatives = (int)(numberOfRows * numberOfColumns * percentageOfNegatives / 100);

	int dice, diceMax = 16; // Helps determine whether to generate a positive number, negative number or powerup.
	float number; // The number to put in the board.

	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			// roll dice; generate number to determine whether
			// a positive number, negative number, or powerup
			// should be placed on the board
			dice = randomNum(1, diceMax - 1, false); 

			if(dice <= diceMax * percentageOfNegatives / 100 && numberOfNegatives <= maxNumberOfNegatives) {
				number = randomNum(min, max, true);
				numberOfNegatives++;
			} else if (dice <= diceMax * (percentageOfPowerups + percentageOfNegatives) / 100 && numberOfPowerups <= maxNumberOfPowerups) {
				number = 69;
				numberOfPowerups++;
			} else {
				number = randomNum(min, max, false);
			}

			*(board + row * numberOfColumns + column) = number;
			*(covered + row * numberOfColumns + column) = true;
		}
	}	

	// Generate random position for exit tile.
	int powerOf2 = 1;
	while(powerOf2 < numberOfRows * numberOfColumns) {
		powerOf2 <<= 1;
	}

	// Make sure position is inside board.
	// Limitation: might not reach other board positions
	// when number of board cells isn't a power of 2.
	if(powerOf2 > numberOfRows * numberOfColumns) {
		powerOf2 >>= 1;
	}

	int exitPosition = randomNum(1, powerOf2 - 1, false); 

	*(board + exitPosition) = 0;	

	printf("\nNumber of powerups: %d/%d (%.2f)\n", 
		numberOfPowerups, 
		numberOfColumns * numberOfRows, 
		(float)((float) 100 * numberOfPowerups / (numberOfColumns * numberOfRows)));
	printf("Number of negatives: %d/%d (%.2f)\n\n", 
		numberOfNegatives, 
		numberOfColumns * numberOfRows, 
		(float)((float) 100 *numberOfNegatives / (numberOfColumns * numberOfRows)));

	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			printf("%-7.2f", *(board + row * numberOfColumns + column));
		}
		printf("\n");
	}	
}

void displayGame(float *board, bool *covered, int numberOfRows, int numberOfColumns) {
	int row, column;

	printf("\n");

	float number;

	bool uncovered = false;

	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
			number = *(board + row * numberOfColumns + column);

			uncovered = !*(covered + row * numberOfColumns + column);

			if(!uncovered) {
				printf("%s%-3s", KCYN, "X");

				continue;
			}

			if(number > 0 && number <= 15) {
				// printf("%-2s", "\u2795");
				printf("%s%-3s", KGRN, "+");
			} else if (number < 0 && number >= -15) {
				// printf("%-2s", "\u274C");
				printf("%s%-3s", KRED, "-");
			} else if (number == 0) {
				// printf("%-2s", "\u274C");
				printf("%s%-3s", KWHT, "*");
			} else {
				// printf("%-2s", "\U0001F4B0");
				printf("%s%-3s", KYEL, "$");
			}
		}
		printf("\n");
	}	
} 

float calculateScore(float *board, bool *covered, int numberOfRows, int numberOfColumns) {
	float totalScore = 0, score;

	for(int row = 0; row <= numberOfRows; row++) {
		for(int column = 0; column <= numberOfColumns; column++) {
			score = *(board + row * numberOfColumns + column);

			if(!*(covered + row * numberOfColumns + column) && score > -15 && score < 15) {
				totalScore += score;
			}
		}
	}

	return totalScore;
}

void logScore(char *name, float score, double time, int numberOfRows, int numberOfColumns) {
	FILE *logFile = fopen("scores.log", "r");
	bool writeHeader = false;
	if(logFile == NULL) {
		writeHeader = true;
	}
	fclose(logFile);

	logFile = fopen("scores.log", "ab+");

	if(writeHeader) {
		fprintf(logFile, "%-15s\t%10s\t%15s\t%30s\n", "name", "score", "time(seconds)", "board size (rows x columns)");
	}

	fprintf(logFile, "%-15s\t%10.2f\t%15.2f\t%25d x %d\n", name, score, time, numberOfRows, numberOfColumns);

	fclose(logFile);
}

void exitGame(char *message) {
	if(*(message) == '\0') {
		message = "You left too early!";
	}

	printf("%s%s", KRED, message);

	exit(0);
}

void playGame(float *board, bool *covered, char *name, int numberOfRows, int numberOfColumns) {
	int bombs = 1;
	bombs += (int)(numberOfRows * numberOfColumns * 0.01);
	int x, y;
	int bombRadius = 1, bombPowerupsCount = 0;
	int lives = 3;
	bool exitFound = false;
	float totalScore = 0, roundScore = 0;

	time_t begin = time(NULL);

	while(bombs > 0 && !exitFound && lives > 0) {
		printf("%sYou have %d bombs left\n", KNRM, bombs);
		printf("If you want to stop playing input \"-1 -1\".\n");
		printf("%sDrop the bomb at (x y): ", KNRM);
		
		// scanned is the number of succesfully scanned inputs.
		int scanned = scanf("%d %d", &x, &y);
		
		if(scanned != 2) {
			exitGame("Sorry, invalid input! You were exited from the game.");
		}

		if(x == -1 || y == -1) {
			break;
		}

		// Check if bombing inside area.
		if(!(x >= 0 && x < numberOfRows && y >= 0 && y < numberOfColumns)) {
			printf("You're bombing outside the bombable range! Try again!");
			x = 0;
			y = 0;
			continue;
		}

		printf("Bombing position: %d, %d...\n", x, y);

		roundScore = 0;

		// calculate start position (top left)
		int start[] = {(x - bombRadius), (y - bombRadius)};
		// calculate end position (bottom right)
		int end[] = {(x + bombRadius), (y + bombRadius)};
		if(start[0] < 0) {
			start[0] = 0;
		}

		if(start[1] < 0) {
			start[1] = 0;
		}

		if(end[0] > numberOfRows - 1) {
			end[0] = numberOfRows - 1;
		}

		if(end[1] > numberOfColumns - 1) {
			end[1] = numberOfColumns - 1;
		}

		bombPowerupsCount = 0;

		for(int row = start[0]; row <= end[0]; row++) {
			for(int column = start[1]; column <= end[1]; column++) {
				if(!*(covered + row * numberOfColumns + column)) {
					continue;
				}

				*(covered + row * numberOfColumns + column) = false;

				float score = *(board + row * numberOfColumns + column);

				if((score > 0 && score <= 15) || (score < 0 && score >= -15)) {
					roundScore += score;
				} else if (score == 69) {
					// count bomb powerups
					bombPowerupsCount++;
				} else if (score == 0) {
					exitFound = true;
				}
			}
		}

		totalScore = calculateScore(board, covered, numberOfRows, numberOfColumns);

		bombRadius = 1;

		if(bombPowerupsCount > 0 && bombs > 1) {
			bombRadius = bombRadius << bombPowerupsCount;

			if(bombPowerupsCount > 30) {
				bombRadius = 2147483647;
			}

			printf("%sBang to the power of %d! Your next bomb's radius is now %d\n", KYEL, bombPowerupsCount, bombRadius);
		}
		

		if(roundScore > 0) {
			printf("%s", KGRN);
		} else if(roundScore < 0) {
			printf("%s", KRED);
		} else {
			printf("%s", KNRM);
		}
		printf("Score for this round: %.2f%s\n", roundScore, KNRM);

		if(totalScore > 0) {
			printf("%s", KGRN);
		} else if(totalScore < 0) {
			printf("%s", KRED);
			// life is lost
			lives--;
			printf("\nYou lost a life!\n");
		} else {
			printf("%s", KNRM);
		}

		printf("Total Score: %.2f", totalScore);

		printf("\nLives Left: %d", lives);

		displayGame(board, covered, numberOfRows, numberOfColumns);
		bombs--;
	}

	time_t end = time(NULL);
	double time_spent = (double)(end - begin);

	printf("\n%sGame Over!", KRED);

	printf("\n%s%s\t%.2f\t%.2f\n", KNRM, name, totalScore, time_spent);

	logScore(name, totalScore, time_spent, numberOfRows, numberOfColumns);
}

void displayTopScores(int n) {
	FILE *logFile = fopen("scores.log", "r");

	char string[100];

	// Skips first line which is the log file column names
	fgets(string, sizeof(string), logFile);

	char name[50], boardSize[50];
	float score, time;

	int count = 0;

	float *scores = malloc(sizeof(float));
	float *times = malloc(sizeof(float));
	char (*names)[sizeof(name)] = malloc(sizeof(char[1][50]));

	char startOfName;

	while((startOfName = fgetc(logFile)) != EOF) {
		fscanf(logFile, "%s", name);
		fscanf(logFile, "%f", &score);
		fscanf(logFile, "%f", &time);
		// skip to end of line
		fgets(string, sizeof(string), logFile);
		count++;
		names = realloc(names, count * sizeof(char[count][50]));
		int index = 1;
		names[count - 1][0] = startOfName;
		while(index < 49) {
			names[count - 1][index] = name[index - 1];
			index++;
		}

		scores = (float *) realloc(scores, count * sizeof(float));
		times = (float *) realloc(times, count * sizeof(float));
		scores[count - 1] = score;
		times[count - 1] = time;
	}

	int row;
	int sortedRows[count];
	// Store the document numbers in an array.
	for(row = 0; row < count; row++) {
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

		for(row = 0; row < count - 1; row++) {
			if (*(scores + sortedRows[row]) < *(scores + sortedRows[row + 1])) {
				tempRow = sortedRows[row];
				sortedRows[row] = sortedRows[row+1];
				sortedRows[row + 1] = tempRow;

				swapped = true;
			}
		}
	} while(swapped);

	if(n > count) {
		n = count;
	}

	printf("%sTop %d Scores:%s\n", KYEL, n, KNRM);

	for(row = 0; row < n; row++) {
		printf("%d. %s\t%.2f\t%.2f\n", row + 1, names[sortedRows[row]], *(scores + sortedRows[row]), *(times + sortedRows[row]));
	}

	fclose(logFile);
}


int main(int argc, char *argv[]) {
	int numberOfRows, numberOfColumns;

	if(argc != 4) {
		printf("Invalid number of arguments.");
		exit(0);
	}

	// Get the number of rows and columns from the 
	// command line arguments.
	numberOfRows = (int) strtol(argv[2], &argv[2], 10);
	numberOfColumns = (int) strtol(argv[3], &argv[3], 10);

	if(numberOfRows < 10 || numberOfColumns < 10) {
		printf("%sSorry, invalid board size. A board must be at least 10 x 10 in size.", KRED);
		exit(0);
	}

	char* name = argv[1];

	// Seed the rand().
	srand(time(0));

	float board[numberOfRows][numberOfColumns];
	bool covered[numberOfRows * numberOfColumns];

	int numOfTopScores = 0;

	printf("How many top scores do you want to be displayed? If you don't want scores to be displayed, just enter 0. ");
	int scanned = scanf("%d", &numOfTopScores);

	if(scanned == 1) {
		displayTopScores(numOfTopScores);
	} else {
		exitGame("Invalid input.");
	}

	initializeGame(*board, covered, numberOfRows, numberOfColumns);
	
	displayGame(*board, covered, numberOfRows, numberOfColumns);

	playGame(*board, covered, name, numberOfRows, numberOfColumns);

	printf("How many top scores do you want to be displayed? If you don't want scores to be displayed, just enter 0. ");
	scanned = scanf("%d", &numOfTopScores);

	if(scanned == 1) {
		displayTopScores(numOfTopScores);
	} else {
		exitGame("Invalid input.");
	}

	printf("%sThank you for playing bomberman!", KGRN);
}