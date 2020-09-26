# CPSC 355 - Assignment 1

This C program sorts and displays the top documents based on a given word's frequency in each document. 

This is quite a simple program and just uses a 2D integer array (that is randomly generated or populated with a text file). The dimensions of the 2D array and filename of the optional file must be passed as command line arguments upon running the program. The documents are represented by the row indices of the array while the words are represented by the column indices of the array. For example, see the table below:

|   |   |   |   |   |
|---|---|---|---|---|
| 7 | 5 | 2 | 1 | 3 |
| 9 | 6 | 8 | 4 | 1 |
| 2 | 4 | 2 | 8 | 6 |
| 9 | 6 | 8 | 4 | 1 |
| 2 | 4 | 2 | 8 | 6 |

In this table, there are 5 documents (0 to 4) and 5 words (0 to 4). `word 3` (4th column) in `document 2` (3rd column) has an *occurence* of 4.

In order to understand the program's objective let us define *size* and *frequency*. 

**Size**

Each document has a size and it is the total number of occurences for each of its words. For example, `document 1` has a size of `7 + 5 + 2 + 1 + 3 = 18`.

**Frequency**

Each word has a frequency in each document. For example `word 0` in `document 1` has an occurence of 7. `word 0`'s frequency in `document 1` is calculated by dividing it's occurence by the document's size. Since `document 1` has a size of 18 we have: `7/18` as the frequency of `word 0` in `document 1`.

Again, the program sorts and displays the top documents based on a given word's frequency in each document. 

## Compile
In order to compile this program, you must have the GCC compiler installed in your environment.

Run the following command to compile: `$ gcc assign1.c -o assign1`

## Run
After compiling this program you may run it. Please do note that this program is able to handle 5-20 documents (rows) and words (columns).

### Without a file
This program requires 2 command line arguments. First, the number of documents, and second, the number of words.

If you don't give a file for the program to read off of, the program will generate a random array with the number of documents and words that you specify.

To run, do as follows: `$ ./assign1 5 6` This will run the program and generate a 2D array with 5 documents and 6 words.

### With a file of your choice
The file must contain integers (0 to 9) formatted in a table (columns are separated by spaces and rows are separated by line breaks) please see the text file in this folder for reference.

Then, to run the program with a given file enter the command in your terminal: `$ ./assign1 5 6 occurrences.txt` This will run the program and read the occurences.txt file. Also, it is important that the number of documents and words you specify when running this command matches the number of documents and words in your file.

