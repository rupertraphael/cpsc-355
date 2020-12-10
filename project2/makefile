mygame:	main.asm	randNum.asm
	m4 main.asm > main.s
	m4 randNum.asm > randNum.s
	as main.s -o main.o -g
	as randNum.s -o randNum.o -g
	gcc main.o randNum.o -o mygame -g
