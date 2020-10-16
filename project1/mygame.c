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

	int percentageOfPowerups = 20, percentageOfNegatives = 35;
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

	printf("Number of powerups: %d\n", numberOfPowerups);
	printf("Number of negatives: %d\n", numberOfNegatives);

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

int main(int argc, char *argv[]) {
	int numberOfRows, numberOfColumns;

	if(argc != 4) {
		printf("Invalid number of arguments.");
		exit(0);
	}

	// Seed the rand().
	srand(time(0));

	// Get the number of rows and columns from the 
	// command line arguments.
	numberOfRows = (int) strtol(argv[2], &argv[2], 10);
	numberOfColumns = (int) strtol(argv[3], &argv[3], 10);
	char* name = argv[1];

	float board[numberOfRows][numberOfColumns];
	bool covered[numberOfRows * numberOfColumns];
	initializeGame(*board, covered, numberOfRows, numberOfColumns);
	
	displayGame(*board, covered, numberOfRows, numberOfColumns);

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
		printf("%sDrop the bomb at (x y): ", KNRM);
		scanf("%d %d", &x, &y);

		// Check if bombing inside area.
		if(!(x >= 0 && x < numberOfRows && y >= 0 && y < numberOfColumns)) {
			printf("You're bombing outside the bombable range! Try again!");
			continue;
		}

		printf("Bombing position: %d, %d...", x, y);

		roundScore = 0;

		// TODO: determine affected positions - depends on radius.
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

		printf("\nstart: %d,%d\n", start[0], start[1]);
		printf("end: %d,%d\n", end[0], end[1]);

		bombPowerupsCount = 0;

		for(int row = start[0]; row <= end[0]; row++) {
			for(int column = start[1]; column <= end[1]; column++) {
				if(!*(covered + row * numberOfColumns + column)) {
					continue;
				}

				*(covered + row * numberOfColumns + column) = false;

				float score = board[row][column];

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

		totalScore = calculateScore(*board, covered, numberOfRows, numberOfColumns);

		bombRadius = 1;

		if(bombPowerupsCount > 0 && bombs > 1) {
			bombRadius = bombRadius << bombPowerupsCount ;
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

		displayGame(*board, covered, numberOfRows, numberOfColumns);
		bombs--;
	}

	time_t end = time(NULL);
	double time_spent = (double)(end - begin);

	printf("\n%sGame Over!", KRED);

	printf("\n%s%s\t%.2f\t%.2f", KNRM, name, totalScore, time_spent);

	logScore(name, totalScore, time_spent, numberOfRows, numberOfColumns);
}