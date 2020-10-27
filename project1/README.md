# CPSC 355 - Project (Part A)

This is an implementation (using the C programming language) of the Bomberman game as described in the project specifications in the course - University of Calgary CPSC 355 - Fall 2020.

The flow is as follows:
1. Asks the user to enter the number of top scores to display from the `scores.log` file if there exists such a file.
2. Game is executed.
3. Logs player's name, score, and time in the `scores.log` file (will be created if it does not exist).
4. Asks the user to enter the number of top scores to display from the top scores from the `scores.log` file.

## Surprise Packs
This implementation of the game includes the required bomb powerup(**$**) and an extra pack called a _landmine_.

A landmine is represented by an **L** in the game board while its trigger is represented by a **T**. A landmine has a bomb radius of 1 and so blows up it's immediate surrounding cells only when the trigger has been uncovered/bombed (i.e. it doesn't blow up when it is directly bombed by the player so it's quite different from an actual landmine *cuz, anyway, this is just a game*).

## Compile
In order to compile this program, you must have the GCC compiler installed in your environment.

Run the following command to compile: `$ gcc mygame.c -o mygame`

## Run
You need to specify the following command line arguments when running:
1. `name` - string
2. `number of rows` - integer greater than 10
3. `number of columns` - integer greater than 10

After compiling this program you may run it (e.g. `$ ./mygame rupert 20 20`).

## Demos
This repository includes `.script` files that demo the program. 

Run `$ cat script.script` to see the program in all it's glory (with colors). If you're on a system that doesn't work with
this program's colored-text, that sucks; but you may look at the `script-no-color.script` file.

## Issues
This program takes advantage of colored-text in terminals. If your terminal doesn't support colored-text (e.g. Windows Command Prompt),
you need to modify lines 13 - 20 of the code in order for it to be displayed properly without colors. Modify the mentioned lines as follows:
```
#define KNRM  ""
#define KRED  ""
#define KGRN  ""
#define KYEL  ""
#define KBLU  ""
#define KMAG  ""
#define KCYN  ""
#define KWHT  ""
```
