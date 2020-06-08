all: parser

CC = g++
LEX = lex
YACC = yacc

parser: lex.l yacc.y symbolTable.h symbolTable.cpp
	$(LEX) lex.l
	$(YACC) -d yacc.y -d
	$(CC) -o parser y.tab.c symbolTable.cpp -ll -ly -std=c++11

.PHONY: clean,run

clean:
	rm lex.yy.c y.tab.* parser

test:
	./parser
