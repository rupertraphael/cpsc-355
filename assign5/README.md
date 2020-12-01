# CPSC 355 - Assignment 5

This program sorts (using bubble sort) and displays the top documents based on a given word's frequency in each document.
(Following the specifications in the document provided by the course.)

After using the program, a log file, `assign5.log`, is generated containing the generated documents-and-words table, user inputs, and search results.

## Files
This project has three files: this readme file, `assign5.log`, `assign5.asm` which must be processed using m4 by running `$ m4 assign5.asm > assign5.s.`

## Compile
Run the following command to compile: `$ gcc assign5.s -o assign5`

## Run
After compiling this program you may run it like `$ ./assign 5 5` or with a text file containing documents and words: `$ ./assign5 5 5 occurences.txt`.
