%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LIST     strcat(buf,yytext)
#define token(t) {LIST; printf("<'%s'>\n",t);}
#define tokenKeyword(t) {LIST; printf("<%s>\n",t);}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);}
#define tokenPlainReal(t,i) {LIST; printf("<%s:%f>\n",t,i);}
#define tokenExpReal(t,i) {LIST; printf("<%s:%e>\n",t,i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s);}

#define MAX_LINE_LENG 256

struct ident {
    int index;
    char str[MAX_LINE_LENG];
    struct ident* next;
};

struct symbolTable {
    int counts;
    struct ident* first;
    struct ident* last;
};

int linenum = 1;
char buf[MAX_LINE_LENG];
struct symbolTable *table;

/* create new symbol table */
struct symbolTable* create() {
	struct symbolTable* new_table;
	new_table = (struct symbolTable*)calloc(1, sizeof(struct symbolTable));
	// avoid memory not enough
	if (new_table == NULL) {
		perror("symbolTable malloc failed");
		exit(-1);
	}
	new_table->counts = 0;

	return new_table;
};

/* lookup identifier is in symbol table or not */
int lookup(struct symbolTable* table, char* s) {
	struct ident* cur;
	for (cur = table->first; cur != NULL; cur = cur->next) {
        // find match ident then return index
		if (!strcmp(cur->str, s)) {
			return cur->index;
		}
	}
    // if not found
	return -1;
}

/* insert identifier in symbol table */
void insert(struct symbolTable* table, char* s) {
    // ensure identifier is not in symbolTable
    if (lookup(table, s) == -1) {
        struct ident* new_ident;
        new_ident = (struct ident*)calloc(1, sizeof(struct ident));
        // avoid memory not enough
        if (new_ident == NULL) {
            perror("ident malloc failed");
            exit(-1);
        }
        strcpy(new_ident->str, s);
        new_ident->index = table->counts;
        table->counts++;

        if (table->first == NULL) {
            table->first = new_ident;
        }
        else {
            table->last->next = new_ident;
        }
        table->last = new_ident;
    }

}

/* print symbol table */
void dump(struct symbolTable* table) {
	printf("Symbol Table:\n");
	struct ident* cur;
	for (cur = table->first; cur != NULL; cur = cur->next) {
		printf("%s\n", cur->str);
	}
}
%}

 /* Definitions */
DIGIT   [0-9]
DIGITS  {DIGIT}+
LETTER  [A-Za-z]
DELIMITER [,:\.;\(\)\[\]\{\}]
ARITHMETIC [\+\-\*\/]
ASSIGNMENT =
REMAINDER %
RELATIONAL <|<=|>=|>|==|!= 
LOGICAL &&|\|\||!
IDENTIFIER {LETTER}({LETTER}|{DIGIT})*
INTEGER {DIGITS}
PLAINREAL {DIGITS}"."{DIGITS}
EXPREAL {DIGITS}"."{DIGITS}[Ee][+-]?{DIGITS}
REAL {PLAINREAL}|{EXPREAL}

%x COMMENT 

%%
 /* Actions */

 /* Keywords */
boolean	{ tokenKeyword("BOOLEAN"); }
break	{ tokenKeyword("BREAK"); }
char	{ tokenKeyword("CHAR"); }
case	{ tokenKeyword("CASE"); }
class	{ tokenKeyword("CLASS"); }
continue	{ tokenKeyword("CONTINUE"); }
def	{ tokenKeyword("DEF"); }
do	{ tokenKeyword("DO"); }
else	{ tokenKeyword("ELSE"); }
exit	{ tokenKeyword("EXIT"); }
false	{ tokenKeyword("FALSE"); }
float	{ tokenKeyword("FLOAT"); }
for	{ tokenKeyword("FOR"); }
if	{ tokenKeyword("IF"); }
int	{ tokenKeyword("INT"); }
null	{ tokenKeyword("NULL"); }
object	{ tokenKeyword("OBJECT"); }
print	{ tokenKeyword("PRINT"); }
println	{ tokenKeyword("PRINTLN"); }
repeat	{ tokenKeyword("REPEAT"); }
return	{ tokenKeyword("RETURN"); }
string	{ tokenKeyword("STRING"); }
to	{ tokenKeyword("TO"); }
true	{ tokenKeyword("TRUE"); }
type	{ tokenKeyword("TYPE"); }
val	{ tokenKeyword("VAL"); }
var	{ tokenKeyword("VAR"); }
while	{ tokenKeyword("WHILE"); }

 /* Delimiters */
{DELIMITER} | 
{ARITHMETIC} |
{REMAINDER} |
{ASSIGNMENT} |
{RELATIONAL} |
{LOGICAL} { token(yytext); }

 /* Integer */
{INTEGER} { tokenInteger("integer", atoi(yytext)); }

 /* Plain Real */
{PLAINREAL} { tokenPlainReal("plain_real", atof(yytext)); }

 /* Exp Real */
{EXPREAL} { tokenExpReal("exp_real", atof(yytext)); }

 /* Identifier */
{IDENTIFIER} { 
    tokenString("id", yytext); 
    insert(table, yytext);
}

 /* C Style Comment */
"/*" { LIST; BEGIN COMMENT; }
<COMMENT>. { LIST; }
<COMMENT>\n  {
    LIST;
    printf("%d: %s", linenum++, buf);
    buf[0] = '\0';
}
<COMMENT>"*/" { LIST; BEGIN INITIAL; }

 /* C++ Style Comment */
"//".* { LIST; }

 /* String */
\"[^\"^\n]*\" { 
    char c = input();
    unput(c);

    if (c == '\"') {
        yymore();
    }
    else {
        yyless(yyleng);
        char str[MAX_LINE_LENG];
        char *pch;
        strncpy(str, yytext + 1, strlen(yytext) - 2);
        str[strlen(yytext)-2] = '\0';
        
        pch = strstr(str, "\"\"");
        while (pch != NULL) {
            strncpy(pch, pch + 1, strlen(pch) - 1);
            str[strlen(str) - 1] = '\0';
            pch = strstr(str, "\"\"");
        }
        tokenString("string", str);
    }
}

 /* Newline */
\n  {
    LIST;
    printf("%d: %s", linenum++, buf);
    buf[0] = '\0';
}

 /* End of file */
<<EOF>> {
    LIST;
    printf("%d: %s\n", linenum++, buf);
    buf[0] = '\0';
    return 0;
}

[ \t]*  {LIST;}

.   {
    LIST;
    printf("%d:%s\n", linenum++, buf);
    printf("bad character:'%s'\n",yytext);
    exit(-1);
}
%%
 /* User codes */
int main() {
        table = create();
        yylex();
        printf("\n");
        dump(table);
}