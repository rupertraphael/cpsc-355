# CPSC 355 - Assignment 3

This assembly language (ARMV8-A instruction set) program multiplies each integer from -15 to 15 with a random number between 0 to 15.

## Compile
In order to compile this program, you must have m4 and the GCC compiler installed in your environment.

Run the following commanda to transpile macros and compile code: 
`$ m4 assign3.asm > assign3.s`
`$ gcc assign3.s -o assign3`

## Run
After compiling this program you may run it.
`$ ./assign3`
