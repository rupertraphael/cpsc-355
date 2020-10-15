#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/*
 * randomNum
 * returns a random number between min and max (inclusive)
 * only correct if max = 2^n - 1 where n is an integer.
 * multiplies the random number by -1 if negative is true.
 */
float randomNum(int min, int max, bool negative) {
	float num; 

	do {
		num = ((rand() + min) & (max)) + ((float)rand() / (float)(RAND_MAX));	
	} while(num < min || num > max);

	if(negative) {
		num *= -1;
	}

	return num;
}

void initializeGame(float *board, bool *covered, int numberOfRows, int numberOfColumns) {
	int row, column;

	int min = 1,max = 15;

	int percentageOfPowerups = 20, percentageOfNegatives = 35;
	int maxNumberOfPowerups, maxNumberOfNegatives;
	int numberOfPowerups = 0, numberOfNegatives = 0;

	maxNumberOfPowerups = (int)(numberOfRows * numberOfColumns * percentageOfPowerups / 100);
	maxNumberOfNegatives = (int)(numberOfRows * numberOfColumns * percentageOfNegatives / 100);

	int dice, diceMax = 16; // Determines whether to generate a positive number, negative number or powerup.
	float number; // The number to put in the board.

	for(row = 0; row < numberOfRows; row++) {
		for(column = 0; column < numberOfColumns; column++) {
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
				printf("%-3s", "X");

				continue;
			}

			if(number > 0 && number <= 15) {
				// printf("%-2s", "\u2795");
				printf("%-3s", "+");
			} else if (number < 0 && number >= -15) {
				// printf("%-2s", "\u274C");
				printf("%-3s", "-");
			} else if (number == 0) {
				// printf("%-2s", "\u274C");
				printf("%-3s", "*");
			} else {
				// printf("%-2s", "\U0001F4B0");
				printf("%-3s", "$");
			}
		}
		printf("\n");
	}	
} 

int main(int argc, char *argv[]) {
	int numberOfRows, numberOfColumns;

	if(argc != 3) {
		printf("Invalid number of arguments.");
		exit(0);
	}

	// Seed the rand().
	srand(time(0));

	// Get the number of rows and columns from the 
	// command line arguments.
	numberOfRows = (int) strtol(argv[1], &argv[1], 10);
	numberOfColumns = (int) strtol(argv[2], &argv[2], 10);

	float board[numberOfRows][numberOfColumns];
	bool covered[numberOfRows * numberOfColumns];
	initializeGame(*board, covered, numberOfRows, numberOfColumns);
	
	displayGame(*board, covered, numberOfRows, numberOfColumns);

	int bombs = 3;
	int x, y;

	while(bombs > 0) {
		printf("Enter bomb position (x y): ");
		scanf("%d %d", &x, &y);
		printf("position: %d, %d", x, y);

		*(covered + x * numberOfRows + y) = false;

		displayGame(*board, covered, numberOfRows, numberOfColumns);
		bombs--;
	}
}