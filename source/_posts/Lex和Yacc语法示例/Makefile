rpc-compiler: lex.o parser.o main.cpp ./src/barrelrpc.if
	g++ -std=c++11 -g -lm -o test lex.o parser.o main.cpp

lex.o: test.l parser.o
	flex test.l
	g++ -c -o lex.o lex.yy.c

parser.o: test.yy
	bison test.yy
	g++ -c -o parser.o test.tab.cc

.PHONY: clean run

clean:
	rm *.hh *.cc lex.yy.c *.o
