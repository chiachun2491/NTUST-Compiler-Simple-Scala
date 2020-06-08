%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbolTable.h"
#include "y.tab.h"

#define LIST     strcat(buf,yytext)
#define token(t) {LIST; printf("<'%s'>\n",t);}
#define tokenKeyword(t) {LIST; printf("<%s>\n",t);}
#define tokenInteger(t,i) {LIST; printf("<%s:%d>\n",t,i);}
#define tokenPlainReal(t,i) {LIST; printf("<%s:%f>\n",t,i);}
#define tokenExpReal(t,i) {LIST; printf("<%s:%e>\n",t,i);}
#define tokenString(t,s) {LIST; printf("<%s:%s>\n",t,s);}
#define tokenChar(t,s) {LIST; printf("<%s:%c>\n",t,s);}

#define MAX_LINE_LENG 256

int linenum = 1;
char buf[MAX_LINE_LENG];
%}

 /* Definitions */
DIGIT   [0-9]
DIGITS  {DIGIT}+
LETTER  [A-Za-z]

IDENTIFIER {LETTER}({LETTER}|{DIGIT})*
CHARACTER ({LETTER}|{DIGIT})
INTEGER {DIGITS}
PLAINREAL {DIGITS}"."{DIGITS}
EXPREAL {DIGITS}"."{DIGITS}[Ee][+-]?{DIGITS}
REAL {PLAINREAL}|{EXPREAL}

%x COMMENT 

%%
 /* Actions */

 /* Integer */
{INTEGER} { 
    sscanf(yytext, "%d", &(yylval.intVal));
    tokenInteger("integer", atoi(yytext)); 
    return(INTEGER_VAL);
}

 /* Exp Real */
{EXPREAL} { 
    sscanf(yytext, "%f", &(yylval.realVal));
    tokenExpReal("exp_real", atof(yytext)); 
    return(REAL_VAL);
}

 /* Plain Real */
{PLAINREAL} { 
    sscanf(yytext, "%f", &(yylval.realVal));
    tokenPlainReal("plain_real", atof(yytext)); 
    return(REAL_VAL);
}

 /* DELIMITER */
"," { token(yytext); return(COMM); }
":" { token(yytext); return(COLO); }
"." { token(yytext); return(PERI); }
";" { token(yytext); return(SEMI); }
"(" { token(yytext); return(PARE_L); }
")" { token(yytext); return(PARE_R); }
"[" { token(yytext); return(SQUE_L); }
"]" { token(yytext); return(SQUE_R); }
"{" { token(yytext); return(BRAC_L); }
"}" { token(yytext); return(BRAC_R); }

 /* ARITHMETIC */
"+" { token(yytext); return(PLUS); }
"-" { token(yytext); return(MINU); }
"*" { token(yytext); return(MULT); }
"/" { token(yytext); return(DIVI); }
"%" { token(yytext); return(REMA); }

 /* ASSIGNMENT */
"=" { token(yytext); return(ASSI); }

 /* RELATIONAL */
"<"     { token(yytext); return(RL_LT); }
"<="    { token(yytext); return(RL_LE); }
">="    { token(yytext); return(RL_GE); }
">"     { token(yytext); return(RL_GT); }
"=="    { token(yytext); return(RL_EQ); }
"!="    { token(yytext); return(RL_NE); }

 /* LOGICAL */
"&&"    { token(yytext); return(LG_AND); }
"||"    { token(yytext); return(LG_OR); }
"!"     { token(yytext); return(LG_NOT); }

 /* ARROW */
"<-"    { token(yytext); return(ARRO); }

 /* Keywords */
boolean	    { tokenKeyword("BOOLEAN"); return(BOOLEAN); }
break	    { tokenKeyword("BREAK"); return(BREAK); }
char	    { tokenKeyword("CHAR"); return(CHAR); }
case	    { tokenKeyword("CASE"); return(CASE); }
class	    { tokenKeyword("CLASS"); return(CLASS); }
continue	{ tokenKeyword("CONTINUE"); return(CONTINUE); }
def	        { tokenKeyword("DEF"); return(DEF); }
do	        { tokenKeyword("DO"); return(DO); }
else	    { tokenKeyword("ELSE"); return(ELSE); }
exit	    { tokenKeyword("EXIT"); return(EXIT); }
false	    { tokenKeyword("FALSE"); return(FALSE); }
float	    { tokenKeyword("FLOAT"); return(FLOAT); }
for	        { tokenKeyword("FOR"); return(FOR); }
if	        { tokenKeyword("IF"); return(IF); }
int	        { tokenKeyword("INT"); return(INT); }
null	    { tokenKeyword("NULL"); return(NULL_); }
object	    { tokenKeyword("OBJECT"); return(OBJECT); }
print	    { tokenKeyword("PRINT"); return(PRINT); }
println	    { tokenKeyword("PRINTLN"); return(PRINTLN); }
read	    { tokenKeyword("READ"); return(READ); }
real	    { tokenKeyword("REAL"); return(REAL); }
repeat	    { tokenKeyword("REPEAT"); return(REPEAT); }
return	    { tokenKeyword("RETURN"); return(RETURN); }
string	    { tokenKeyword("STRING"); return(STRING); }
to	        { tokenKeyword("TO"); return(TO); }
true	    { tokenKeyword("TRUE"); return(TRUE); }
type	    { tokenKeyword("TYPE"); return(TYPE); }
val	        { tokenKeyword("VAL"); return(VAL); }
var	        { tokenKeyword("VAR"); return(VAR); }
while	    { tokenKeyword("WHILE"); return(WHILE); }

 /* Identifier */
{IDENTIFIER} { 
    tokenString("id", yytext);
    yylval.strVal = strdup(yytext);
    return(IDENT);
}

 /* Character */
\'{CHARACTER}\' { 
    sscanf(yytext, "%c", &(yylval.charVal));
    tokenChar("char", yytext[0]);
    return(CHAR_VAL);
}

 /* String */
\"[^\"^\n]*\" { 
    char c = getc(yyin);
    ungetc(c, yyin);

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
        yylval.strVal = strdup(str);
        return(STRING_VAL);
    }
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

[ \t\r]*  {LIST;}

.   {
    LIST;
    printf("%d:%s\n", linenum++, buf);
    printf("bad character:'%s'\n",yytext);
    exit(-1);
}
%%