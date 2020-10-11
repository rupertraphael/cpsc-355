# CPSC 355 - Assignment 2

This assembly language (ARMV8-A instruction set) program generates _n_ random numbers specified by the user. Each random number represents occurences for a word in a document.

The highest and lowest frequencies for each word is then displayed to the user.

**Size**

The sum of all the occurences.

**Frequency**

The percentage of the occurence of a word divided by the size.

## Files
This project has two files: `assign2a.s`; and `assign2b.asm` which must be processed using m4 by running `$ m4 assign2b.asm > assign2b.s.`

## Compile
In order to compile this program, you must have the GCC compiler installed in your environment.

Run the following command to compile: `$ gcc assign2a.s -o assign2a` or `$ gcc assign2b.s -o assign2b`

## Run
After compiling this program you may run it.
