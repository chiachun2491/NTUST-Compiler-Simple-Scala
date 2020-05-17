all: scanner

CC = cc
LEX = lex

scanner: lex.l
	$(LEX) lex.l
	$(CC) -o scanner -O lex.yy.c -ll

.PHONY: clean,run
clean:
	rm lex.yy.c scanner

test:
	./scanner
