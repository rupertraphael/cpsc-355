mygame:	main.asm	randNum.asm
	m4 main.asm > main.s
	m4 randNum.asm > randNum.s
	as main.s -o main.o
	as randNum.s -o randNum.o
	gcc main.o randNum.o -g -o mygame
