%{
//the following are UBUNTU/LINUX, and MacOS ONLY terminal color codes.
#define RESET       "\033[0m"
#define BOLDRED     "\033[1m\033[31m"      /* Bold Red */
#define BOLDYELLOW  "\033[1m\033[33m"      /* Bold Yellow */
#define BOLDMAGENTA "\033[1m\033[35m"      /* Bold Magenta */
#define BOLDBLUE    "\033[1m\033[34m"      /* Bold Blue */
#define BOLDWHITE   "\033[1m\033[37m"      /* Bold White */

// #define TRACE
#ifdef TRACE
#define Trace(t)        std::cout << BOLDBLUE << "Trace: " << BOLDWHITE << t << RESET <<std::endl
#else
#define Trace(t)        std::cout << ""
#endif

#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <stack>
#include "lex.yy.c"

using namespace std;

symbolTable* nowScope;      // symbolTable of nowScope
symbolTable* fatherScope;   // symbolTable of outsideScope
ident* nowIdent;            // identifer 
vector<int> para;           // method parameters

string filename = "";       // file name
string rawname = "";        // file name without extension  

bool mainMethod = false;    // main method flag
bool assignValue = false;   // assign value flag

ofstream fout;              // bytecode file stream
int tabs = 0;               // tabs number for output

bool canWrite = true;       // switch to dual_write
bool elseBranch = false;    // flag to record need else branch number

int branchIndex = 0;        // branch index
stack<int> branch;          // stack to store branch number

// union data for declaration
int integerValue = 0;
double realValue = 0.0;
char charValue = ' ';
std::string stringValue = "";
bool boolValue = true;

void yyerror(std::string msg) {
    std::cerr << BOLDYELLOW << filename << ":" << linenum << ": warning: " << BOLDWHITE << msg << RESET << std::endl;
}

void yyerror(std::string msg, int customLinenum) {
    std::cerr << BOLDYELLOW << filename << ":" << customLinenum << ": warning: " << BOLDWHITE << msg << RESET << std::endl;
}

void dual_write(ofstream &fs, std::string str) {
    if (str.rfind("L", 0) != 0) {
        // str not starts with prefix L label
        if (!canWrite) {
            for (int i = 0; i < tabs; i++) {
                if (!i) {
                    str = "  " + str;
                }
                else {
                    str = "    " + str;
                }
            } 
            str = "/*" + str + " */" ;
        }
        else {
            for (int i = 0; i < tabs; i++) {
                str = "    " + str;
            } 
        }
    }
    
    std::cout << str << std::endl;
    fs << str << std::endl;
}

std::string adjustStr(std::string str) //j
{
    std::string result = "";
	for (int i = 0; i < str.length(); i++)
	{
		switch (str[i])
		{
		case '\b':
            result += "\\b";
			break;
		case '\t':
            result += "\\t";
			break;
		case '\n':
            result += "\\n";
			break;
		case '\f':
            result += "\\f";
			break;
		case '\r':
            result += "\\r";
			break;
		case '\'':
            result += "\\\'";
			break;
		case '\"':
            result += "\\\"";
			break;
		case '\\':
            result += "\\\\";
			break;
		default:
            result += string(1, str[i]) ;
			break;
		}
	}
	return result;
}

%}
%union {
    int intVal;
    float realVal;
    char charVal;
    bool boolVal;
    char* strVal;
}

/* tokens */
%token <intVal> INTEGER_VAL 
%token <realVal> REAL_VAL 
%token <charVal> CHAR_VAL 
%token <strVal> STRING_VAL
%token COMM COLO PERI SEMI
%token PARE_L PARE_R SQUE_L SQUE_R BRAC_L BRAC_R
%token PLUS MINU MULT DIVI REMA
%token ASSI
%token RL_LT RL_LE RL_GE RL_GT RL_EQ RL_NE
%token LG_AND LG_OR LG_NOT
%token ARRO
%token BOOLEAN BREAK CHAR CASE CLASS CONTINUE DEF DO ELSE EXIT FALSE FLOAT FOR IF INT
%token NULL_ OBJECT PRINT PRINTLN READ REAL REPEAT RETURN STRING TO TRUE TYPE VAL VAR WHILE
%token <strVal> IDENT

%left LG_OR
%left LG_AND
%left LG_NOT
%left RL_LT RL_LE RL_GE RL_GT RL_EQ RL_NE
%left PLUS MINU
%left MULT DIVI REMA
%nonassoc U_MINU

%type <boolVal> boolean_value

%type <intVal> types
%type <intVal> option_types
%type <intVal> option_assign_value

%type <intVal> expression
%type <intVal> function_invocation
%type <intVal> const_expression
%type <intVal> array_reference

%%
program: object_;

object_: OBJECT IDENT BRAC_L { 
            Trace("object_: create new symbolTable.");
            nowScope = new symbolTable($2, NULL); 
            
            dual_write(fout, "class " + string($2));
            dual_write(fout, "{");
            tabs++;
         }
         object_inside_statements BRAC_R {
             nowIdent = nowScope->lookup("main", false);
             if (nowIdent == NULL) {
                 yyerror("object need a main entry method.", 0);
             } 
             else if (nowIdent->type < METHOD_TYPE_FUNC || nowIdent->type > METHOD_TYPE_BOOL) {
                 yyerror("identifier main need to set as method-type", 0);
             }

             tabs--;
             dual_write(fout, "}");
             fout.close();
         };

object_inside_statements: /* empty */
                        | object_inside_statement object_inside_statements;

object_inside_statement: var_const_declaration 
                       | method_declartion
                       ;

var_const_declaration: VAL const_declaration
                    |  VAR var_declaration;

const_declaration: IDENT option_types ASSI const_expression { 
                    Trace("const_declaration:");
                    if (nowScope->lookup($1, false) == NULL) {
                        if ($2 != TYPE_NOT_DEFINE) {
                            nowScope->insert($1, CONST_INTEGER + $2);
                            if ($2 != $4) {
                                yyerror("Constant declartion type not equal with value type.", linenum - 1);
                            }
                        }
                        else {
                            nowScope->insert($1, CONST_INTEGER + $4);
                        }

                        // set accessBC
                        Trace("const_declaration set accessBC");
                        nowIdent = nowScope->lookup($1, false);
                        if (nowIdent != NULL) {
                            switch (nowIdent->type) {
                            case CONST_INTEGER:
                                nowIdent->accessBC = "sipush " + to_string(integerValue);
                                integerValue = 0;
                                break;
                            case CONST_REAL:
                                nowIdent->accessBC = "sipush " + to_string(realValue);
                                realValue = 0.0;
                                break;
                            case CONST_CHAR:
                                nowIdent->accessBC = "ldc \"" + string(1, charValue) + "\"";
                                charValue = ' ';
                                break;
                            case CONST_STRING: 
                                nowIdent->accessBC = "ldc \"" + adjustStr(stringValue) + "\"";
                                stringValue = "";
                                break;
                            case CONST_BOOL:
                                if (boolValue) {
                                    nowIdent->accessBC = "iconst_1";
                                }
                                else {
                                    nowIdent->accessBC = "iconst_0";
                                }
                                boolValue = true;
                                break;
                            default:
                                yyerror("const_declaration occur not const type.");
                                break;
                            }
                            Trace("const_declaration set accessBC done " + nowIdent->accessBC);
                        }
                        else {
                            yyerror("const_declaration not success.");
                        }
                    }
                    else {
                        yyerror(string($1) + " already declared.", linenum - 1);
                    }
                 }
                 ;

option_types: /* empty */ { $$ = TYPE_NOT_DEFINE; }
            | COLO types { $$ = $2; }
            ;

types: 
       INT { $$ = 0; }
     | REAL { $$ = 1; }
     | FLOAT { $$ = 1; }
     | CHAR { $$ = 2; }
     | STRING { $$ = 3; }
     | BOOLEAN { $$ = 4; }
     ;

const_expression: 
                  INTEGER_VAL { 
                    $$ = 0;
                    integerValue = $1;
                  }
                | REAL_VAL { 
                    $$ = 1;
                    realValue = $1; 
                  }
                | CHAR_VAL { 
                    $$ = 2; 
                    charValue = $1; 
                  }
                | STRING_VAL { 
                    $$ = 3; 
                    stringValue = string($1);
                  }
                | boolean_value { 
                    $$ = 4;
                    boolValue = $1; 
                  }
                ;

boolean_value: TRUE { $$ = true; } | FALSE { $$ = false; };

var_declaration: IDENT option_types option_assign_value { 
                    Trace("var_declaration:");
                    if (nowScope->lookup($1, false) == NULL) {
                        if ($2 != TYPE_NOT_DEFINE && $3 != TYPE_NOT_DEFINE) {
                            nowScope->insert($1, INTEGER_VAR + $2);
                            if ($2 != $3) {
                                yyerror("Variable declartion type not equal with value type.", linenum - 1);
                            }
                        }
                        else if ($2 == TYPE_NOT_DEFINE && $3 != TYPE_NOT_DEFINE) {
                            nowScope->insert($1, INTEGER_VAR + $3);
                        }
                        else if ($2 != TYPE_NOT_DEFINE && $3 == TYPE_NOT_DEFINE) {
                            nowScope->insert($1, INTEGER_VAR + $2);
                        }
                        else if ($2 == TYPE_NOT_DEFINE && $3 == TYPE_NOT_DEFINE) {
                            nowScope->insert($1, $2);
                        }
                        else {
                            yyerror("Variable declartion occur unknow error.", linenum - 1);
                        }

                        // set accessBC
                        nowIdent = nowScope->lookup($1, false);
                        if (nowIdent != NULL) {
                            // set bytecode whatever the typeCheck
                            if (nowScope->fatherTable != NULL) {
                                nowIdent->accessBC = "iload " + to_string(nowScope->localValIndex);
                                nowIdent->storeBC = "istore " + to_string(nowScope->localValIndex);
                                nowScope->localValIndex++;

                                if (assignValue) {
                                    Trace("var_declaration local var assignValue");
                                    assignValue = false;
                                    switch (nowIdent->type) {
                                    case INTEGER_VAR:
                                        dual_write(fout, "sipush " + to_string(integerValue));
                                        dual_write(fout, nowIdent->storeBC);
                                        integerValue = 0;
                                        break;
                                    case BOOL_VAR:
                                        if (boolValue) {
                                            dual_write(fout, "iconst_1");
                                        }
                                        else {
                                            dual_write(fout, "iconst_0");
                                        }
                                        dual_write(fout, nowIdent->storeBC);
                                        boolValue = true;
                                        break;
                                    default:
                                        break;
                                    }
                                }
                            }
                            else {
                                nowIdent->accessBC = "getstatic int " + nowScope->scopeName + "." + nowIdent->name;
                                nowIdent->storeBC = "putstatic int " + nowScope->scopeName + "." + nowIdent->name;

                                if (assignValue) {
                                    Trace("var_declaration global var assignValue");
                                    assignValue = false;
                                    switch (nowIdent->type) {
                                    case INTEGER_VAR:
                                        dual_write(fout, "field static int " + nowIdent->name + " = " + to_string(integerValue));
                                        integerValue = 0;
                                        break;
                                    case BOOL_VAR:
                                        if (boolValue) {
                                            dual_write(fout, "field static int " + nowIdent->name + " = 1");
                                        }
                                        else {
                                            dual_write(fout, "field static int " + nowIdent->name + " = 0");
                                        }
                                        boolValue = true;
                                        break;
                                    default:
                                        break;
                                    }
                                }
                                else {
                                    dual_write(fout, "field static int " + nowIdent->name);
                                }
                            }
                            
                            // Warning
                            switch (nowIdent->type) {
                            case INTEGER_VAR:
                            case BOOL_VAR:
                                break;
                            default:
                                yyerror("var_declaration occur not integer/boolean type.");
                                break;
                            }

                            
                        }
                        else {
                            yyerror("var_declaration not success.");
                        } 
                    }
                    else {
                        yyerror(string($1) + " already declared.", linenum - 1);
                    }
               }
               | array_declartion
               ;

option_assign_value: /* empty */ { $$ = TYPE_NOT_DEFINE; }
                   | ASSI const_expression { $$ = $2; assignValue = true; }
                   ;

array_declartion: IDENT COLO types SQUE_L INTEGER_VAL SQUE_R { 
                    Trace("array_declartion:");
                    if (nowScope->lookup($1, false) == NULL) {
                        nowScope->insert($1, INTEGER_ARRAY + $3); 
                    }
                    else {
                        yyerror(string($1) + " already declared.", linenum - 1);
                    }
                } 
                ;

method_declartion: DEF IDENT { 
                    Trace("method_declartion:");
                    // legal method
                    if (nowScope->lookup($2, false) == NULL) {
                        nowScope->insert($2, METHOD_TYPE_NOT_DEFINE); 
                        nowIdent = nowScope->lookup($2, false);
                        nowScope = nowScope->createChild($2); 
                    }
                    // illegal method
                    else {
                        yyerror(string($2) + " already declared.");

                        canWrite = false;
                        nowIdent = new ident($2, METHOD_TYPE_NOT_DEFINE);
                        nowScope = nowScope->createChild("temp_method"); 
                    }
                } 
                PARE_L option_method_formal_arguments PARE_R option_method_return_type {
                    Trace("method_declartion set accessBC and bytecode");

                    // return type
                    string returnTypeStr = "void ";
                    switch (nowIdent->type) {
                    case METHOD_TYPE_FUNC:
                        break;
                    case METHOD_TYPE_INTEGER:
                    case METHOD_TYPE_BOOL:
                        returnTypeStr = "int ";
                        break;
                    default:
                        yyerror("method_declartion return type not integer/boolean/void type.");
                        break;
                    }

                    // method name and formal arguments
                    string nameArguments = nowIdent->name;
                    nameArguments += "(";
                    for (int i = 0; i < nowIdent->args.size(); i++) {
                        if (i) {
                            nameArguments += ", ";
                        }
                        switch (nowIdent->args[i]) {
                        case INTEGER_VAR:
                        case BOOL_VAR:
                            nameArguments += "int";
                            break;
                        default:
                            nameArguments += "int";
                            yyerror("method_declartion formal argument type not integer/boolean type.");
                            break;
                        }
                    }
                    nameArguments += ")";
                    
                    // set accessBC
                    nowIdent->accessBC = "invokestatic " + returnTypeStr + nowScope->fatherTable->scopeName + "." + nameArguments;
                    
                    // declartion bytecode
                    if (nowIdent->name == "main") {
                        dual_write(fout, "method public static void main(java.lang.String[])"); 
                        if (nowIdent->args.size() > 0) {
                            yyerror("main function cannot overwrite formal argument.");
                        }
                    }
                    else {
                        dual_write(fout, "method public static " + returnTypeStr + nameArguments);
                    }
                    dual_write(fout, "max_stack 15");
                    dual_write(fout, "max_locals 15");
                    dual_write(fout, "{");
                    tabs++;
                }
                block {
                    if (!nowScope->returnCheck) {
                        dual_write(fout, "return");
                    }

                    tabs--;
                    dual_write(fout, "}");

                    fatherScope = nowScope->fatherTable;
                    delete nowScope;
                    nowScope = fatherScope;

                    canWrite = true;
                };
                
option_method_formal_arguments: /* empty */ 
                              | method_formal_arguments;

method_formal_arguments: method_formal_argument 
                       | method_formal_argument COMM method_formal_arguments;

method_formal_argument: IDENT COLO types { 
                            Trace("method_formal_argument:");
                            nowIdent->addParam(INTEGER_VAR + $3);
                            Trace("size: " + to_string(nowIdent->args.size()));

                            nowScope->insert($1, INTEGER_VAR + $3);
                            ident* arguIdent = nowScope->lookup($1, false);
                            if (arguIdent != NULL) {
                                arguIdent->accessBC = "iload " + to_string(nowScope->localValIndex);
                                arguIdent->storeBC = "istore " + to_string(nowScope->localValIndex);
                                nowScope->localValIndex++;
                            }
                            else {
                                yyerror("method_formal_argument occur error");
                            }
                        }
                        ;

option_method_return_type: /* empty */ { 
                            nowIdent->type = METHOD_TYPE_FUNC;
                            nowScope->returnType = METHOD_TYPE_FUNC;
                         }
                         | COLO types { 
                            nowIdent->type = METHOD_TYPE_INTEGER + $2;
                            nowScope->returnType = METHOD_TYPE_INTEGER + $2;
                         }
                         ;

block: { Trace("block:"); } BRAC_L block_inside_statements BRAC_R;

block_inside_statements: /* empty */
                       | block_inside_statement block_inside_statements
                       ;

block_inside_statement: var_const_declaration | statement;

statement: statement_1
         | statement_2
         | statement_3
         | statement_4
         | statement_5
         | conditional_statement
         | while_loop_statement
         | for_loop_statement
         | procedure_invocation
         ; 

statement_1: IDENT ASSI expression { 
                Trace("statement_1:");
                Trace("linenum:" + to_string(linenum));
                nowIdent = nowScope->lookup($1, true);
                if (nowIdent == NULL) {
                    yyerror(string($1) + " not declared.", linenum - 1);
                }
                else {
                    // set bytecode whatever type check
                    dual_write(fout, nowIdent->storeBC);

                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                        yyerror(string($1) + " is constant, can't reassign.", linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                        yyerror(string($1) + " is array, can't assign value.", linenum - 1);
                    }
                    else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                        yyerror(string($1) + " is function, can't assign value.", linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                        if (nowIdent->type % TYPE_COUNT != $3) {
                            yyerror(string($1) + " data type not correct, can't assign value.", linenum - 1);
                        }
                    }
                    else if (nowIdent->type == TYPE_NOT_DEFINE) {
                        string msg = string($1) + " is non define type variable, can assign.";
                        switch ($3) {
                        case 2:
                            nowIdent->type = INTEGER_VAR;
                            break;
                        case 3:
                            nowIdent->type = REAL_VAR;
                            break;
                        case 4:
                            nowIdent->type = CHAR_VAR;
                            break;
                        case 0:
                            nowIdent->type = STRING_VAR;
                            break;
                        case 1:
                            nowIdent->type = BOOL_VAR;
                            break;
                        default:
                            break;
                        }
                    }
                    else {
                        yyerror(string($1) + " occur unknow error.", linenum - 1);
                    }
                }
           }
           ;

statement_2: IDENT SQUE_L integer_expression SQUE_R ASSI expression {
                Trace("statement_2:");

                // warning array
                yyerror("Array not supported in this program.", linenum - 1);

                // still check grammar
                nowIdent = nowScope->lookup($1, true);
                if (nowIdent == NULL) {
                    yyerror(string($1) + " not declared.", linenum - 1);
                }
                else {
                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                        yyerror(string($1) + " is constant, not array.", linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                        if (nowIdent->type % TYPE_COUNT != $6) {
                            yyerror(string($1) + " data type not correct, can't assign value.", linenum - 1);
                        }
                    }
                    else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                        yyerror(string($1) + " is function, not array.", linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                        yyerror(string($1) + " is variable, not array.", linenum - 1);
                    }
                    else {
                        yyerror(string($1) + " occur unknow error.", linenum - 1);
                    }
                }
            }
            ;

statement_3: PRINT {
                dual_write(fout, "getstatic java.io.PrintStream java.lang.System.out");
            }
             PARE_L expression PARE_R { 
                Trace("statement_3:");
                // integer/boolean expression
                if ($4 == 2 || $4 == 1 ) {
                    dual_write(fout, "invokevirtual void java.io.PrintStream.print(int)");
                }
                // string expression
                else if ($4 == 0) {
                    dual_write(fout, "invokevirtual void java.io.PrintStream.print(java.lang.String)");
                }
                else {
                    yyerror("This expression can't print.", linenum - 1);
                    // fix the stack
                    dual_write(fout, "pop");
                    dual_write(fout, "ldc \"TYPE_ERROR\"");
                    dual_write(fout, "invokevirtual void java.io.PrintStream.print(java.lang.String)");
                }
            }
           | PRINTLN {
                dual_write(fout, "getstatic java.io.PrintStream java.lang.System.out");
            } 
            PARE_L expression PARE_R { 
                Trace("statement_3:");
                // integer/boolean expression
                if ($4 == 2 || $4 == 1 ) {
                    dual_write(fout, "invokevirtual void java.io.PrintStream.println(int)");
                }
                // string expression
                else if ($4 == 0) {
                    dual_write(fout, "invokevirtual void java.io.PrintStream.println(java.lang.String)");
                }
                else {
                    yyerror("This expression can't print.", linenum - 1);
                    // fix the stack
                    dual_write(fout, "pop");
                    dual_write(fout, "ldc \"TYPE_ERROR\"");
                    dual_write(fout, "invokevirtual void java.io.PrintStream.println(java.lang.String)");
                }
           }
           ;

statement_4: READ IDENT {
                Trace("statement_4:");

                // warning read
                yyerror("read not supported in this program.", linenum - 1);

                // still check grammar
                nowIdent = nowScope->lookup($2, true);
                if (nowIdent == NULL) {
                    yyerror(string($2) + " not declared.", linenum - 1);
                }
                else {
                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                        yyerror(string($2) + " is constant, can't reassign.", linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                        yyerror(string($2) + " is array, can't assign.", linenum - 1);
                    }
                    else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                        yyerror(string($2) + " is function, can't assign.", linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                        string msg = string($2) + " is variable, can reassign.";
                    }
                    else if (nowIdent->type == TYPE_NOT_DEFINE) {
                        string msg = string($2) + " is non define type variable, can assign.";
                    }
                    else {
                        yyerror(string($2) + " occur unknow error.", linenum - 1);
                    }
                }
           }
           ;

statement_5: RETURN {
                Trace("statement_5: RETURN");

                // set bytecode whatever type check
                dual_write(fout, "return");
                
                symbolTable* temp_scope = nowScope;
                while (temp_scope->returnType == NON_TYPE) {
                    if (temp_scope->fatherTable == NULL) {
                        break;
                    }
                    temp_scope = temp_scope->fatherTable;
                }
                Trace("Return scope name:" + temp_scope->scopeName);
                temp_scope->returnCheck = true;
                if (temp_scope->returnType != METHOD_TYPE_FUNC) {
                    if (temp_scope->returnType >= METHOD_TYPE_INTEGER && temp_scope->returnType <= METHOD_TYPE_BOOL) {
                        yyerror(temp_scope->scopeName + " need return value.", linenum - 1);
                    }
                    else {
                        yyerror("Don't do return in non-method scope.", linenum - 1);
                    }
                }
            }
           | RETURN expression { 
                Trace("statement_5: RETURN expression");
                
                // set bytecode whatever type check
                dual_write(fout, "ireturn");

                symbolTable* temp_scope = nowScope;
                while (temp_scope->returnType == NON_TYPE) {
                    if (temp_scope->fatherTable == NULL) {
                        break;
                    }
                    temp_scope = temp_scope->fatherTable;
                }
                Trace("Return scope name:" + temp_scope->scopeName);
                temp_scope->returnCheck = true;
                if (temp_scope->returnType >= METHOD_TYPE_INTEGER && temp_scope->returnType <= METHOD_TYPE_BOOL) {
                    if (temp_scope->returnType % TYPE_COUNT != $2) {
                        yyerror("Return type error.", linenum - 1);
                    }
                }
                else {
                    if (temp_scope->returnType == METHOD_TYPE_FUNC) {
                        yyerror(temp_scope->scopeName + " no need return value.", linenum - 1);
                    }
                    else {
                        yyerror("Don't do return in non-method scope.", linenum - 1);
                    }
                }
            }
           ;

conditional_statement: { Trace("conditional_statement:"); } IF PARE_L boolean_expression PARE_R {
                            elseBranch = false;
                            branch.push(branchIndex + 1);
                            branch.push(branchIndex);
                            branch.push(branchIndex + 1);
                            branch.push(branchIndex);
                            branchIndex += 2;

                            dual_write(fout, "ifeq L" + to_string(branch.top()));
                            branch.pop();
                        } 
                        block_or_simple_statement option_else_statement {
                            if (elseBranch) {
                                dual_write(fout, "L" + to_string(branch.top()) + ":");
                            }
                            branch.pop();
                        };

block_or_simple_statement: {
                               Trace("block_or_simple_statement:");
                               nowScope = nowScope->createChild("temp_block"); 
                           } block {
                               fatherScope = nowScope->fatherTable;
                               delete nowScope;
                               nowScope = fatherScope;
                           } 
                           | statement;

option_else_statement: /* empty */ {
                        branch.pop();
                        dual_write(fout, "L" + to_string(branch.top()) + ":");
                        branch.pop();
                      }
                      | ELSE {
                          elseBranch = true;
                          
                          int gotoIndex = branch.top();
                          branch.pop();
                          int labelIndex = branch.top();
                          branch.pop();

                          dual_write(fout, "goto L" + to_string(gotoIndex));
                          dual_write(fout, "L" + to_string(labelIndex) + ":");
                      } block_or_simple_statement;

while_loop_statement: { Trace("while_loop_statement:"); } WHILE {
                            branch.push(branchIndex + 1);
                            branch.push(branchIndex);
                            branch.push(branchIndex + 1);
                            branch.push(branchIndex);
                            branchIndex += 2;

                            dual_write(fout, "L" + to_string(branch.top()) + ":");
                            branch.pop();
                      } 
                      PARE_L boolean_expression PARE_R {
                          dual_write(fout, "ifeq L" + to_string(branch.top()));
                          branch.pop();
                      } 
                      block_or_simple_statement {
                          int gotoIndex = branch.top();
                          branch.pop();
                          int labelIndex = branch.top();
                          branch.pop();

                          dual_write(fout, "goto L" + to_string(gotoIndex));
                          dual_write(fout, "L" + to_string(labelIndex) + ":");
                      };

for_loop_statement: FOR PARE_L IDENT {
                        Trace("for_loop_statement:");
                        nowIdent = nowScope->lookup($3, true);
                        if (nowIdent == NULL) {
                            yyerror(string($3) + " not declared.");
                        }
                        else if (nowIdent->type != INTEGER_VAR) {
                            yyerror(string($3) + " not integer.");
                        }
                    }
                    ARRO INTEGER_VAL TO INTEGER_VAL {
                        // push initialValue
                        dual_write(fout, "sipush " + to_string($6));
                        // store to ident
                        dual_write(fout, nowIdent->storeBC);

                        branch.push(branchIndex + 1);
                        branch.push(branchIndex);
                        branch.push(branchIndex + 1);
                        branch.push(branchIndex);
                        branchIndex += 2;

                        dual_write(fout, "L" + to_string(branch.top()) + ":");
                        branch.pop();

                    } PARE_R block_or_simple_statement {
                        // push initialValue
                        dual_write(fout, "sipush " + to_string($8));
                        // get identValue
                        nowIdent = nowScope->lookup($3, true);
                        if (nowIdent != NULL) {
                            dual_write(fout, nowIdent->accessBC);
                        }
                        else {
                            yyerror(string($3) + " not found (occur error at forloop bytecode).");
                        }
                        // ifequal exit
                        dual_write(fout, "isub");
                        dual_write(fout, "ifeq L" + to_string(branch.top()));
                        branch.pop();

                        // ident ++ and save
                        dual_write(fout, "iconst_1");
                        if (nowIdent != NULL) {
                            dual_write(fout, nowIdent->accessBC);
                        }
                        else {
                            yyerror(string($3) + " not found (occur error at forloop bytecode).");
                        }
                        dual_write(fout, "iadd");
                        if (nowIdent != NULL) {
                            dual_write(fout, nowIdent->storeBC);
                        }
                        else {
                            yyerror(string($3) + " not found (occur error at forloop bytecode).");
                        }

                        // goback
                        dual_write(fout, "goto L" + to_string(branch.top()));
                        branch.pop();

                        // exit label
                        dual_write(fout, "L" + to_string(branch.top()) + ":");
                        branch.pop();
                    };

procedure_invocation: IDENT {
                        Trace("procedure_invocation:");
                        nowIdent = nowScope->lookup($1, true);
                        if (nowIdent == NULL) {
                            yyerror(string($1) + " not declared.");
                        }
                        else {
                            // set bytecode whatever type check
                            dual_write(fout, nowIdent->accessBC);

                            if (nowIdent->type != METHOD_TYPE_FUNC) {
                                yyerror(string($1) + " not no-return method.");
                            }
                            if (nowIdent->args.size() != 0) {
                                yyerror(string($1) + " need argument.");
                            }
                        }
                        
                    } | IDENT PARE_L option_comma_separated_expressions PARE_R {
                        Trace("procedure_invocation:");
                        nowIdent = nowScope->lookup($1, true);
                        if (nowIdent == NULL) {
                            yyerror(string($1) + " not declared.");
                        }
                        else {
                            // set bytecode whatever type check
                            dual_write(fout, nowIdent->accessBC);

                            if (nowIdent->type != METHOD_TYPE_FUNC) {
                                yyerror(string($1) + " not no-return method.");
                            }
                            Trace("nowIdent->name " + nowIdent->name + to_string(nowIdent->args.size()) + " " + to_string(para.size()));
                            if (nowIdent->args.size() > para.size()) {
                                yyerror("Few arguments in " + string($1) +".");
                            }
                            else if (nowIdent->args.size() < para.size()) {
                                yyerror("Over arguments in " + string($1) +".");
                            }
                            else {
                                bool typeCheck = true;
                                for (int i = 0; i < para.size(); i++) {
                                    Trace("typeCheck " + to_string(i) + " : " + to_string(nowIdent->args[i]) + " " + to_string(para[i]));
                                    if (nowIdent->args[i] % TYPE_COUNT != para[i]) {
                                        typeCheck = false;
                                        break;
                                    }
                                }
                                if (!typeCheck) {
                                    yyerror(string($1) + " argument type check error.");
                                }
                            }
                        }
                    }
                    ;

expression: expression LG_OR expression {
              Trace("expression LG_OR expression:");

              // set bytecode whatever type check
              dual_write(fout, "ior");

              if ($1 == 1 && $3 == 1){
                  $$ = $1;
              }
              else {
                  yyerror("can't use on non-boolean.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression LG_AND expression {
              Trace("expression LG_AND expression:");

              // set bytecode whatever type check
              dual_write(fout, "iand");

              if ($1 == 1 && $3 == 1){
                  $$ = $1;
              }
              else {
                  yyerror("can't use on non-boolean.");
                  $$ = TYPE_ERROR;
              }
          }
          | LG_NOT expression {
              Trace("LG_NOT expression:");

              // set bytecode whatever type check
              dual_write(fout, "iconst_1");
              dual_write(fout, "ixor");

              Trace(to_string($2));
              if ($2 == 1){
                  $$ = $2;
              }
              else {
                  yyerror("can't use on non-boolean.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_LT expression {
              Trace("expression RL_LT expression:");

              // set bytecode whatever type check
              dual_write(fout, "isub");
              dual_write(fout, "iflt L" + to_string(branchIndex));
              dual_write(fout, "iconst_0");
              dual_write(fout, "goto L" + to_string(branchIndex + 1));
              dual_write(fout, "L" + to_string(branchIndex) + ":");
              dual_write(fout, "iconst_1");
              dual_write(fout, "L" + to_string(branchIndex + 1) + ":");
              branchIndex += 2;

              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_LE expression {
              Trace("expression RL_LE expression:");
              
              // set bytecode whatever type check
              dual_write(fout, "isub");
              dual_write(fout, "ifle L" + to_string(branchIndex));
              dual_write(fout, "iconst_0");
              dual_write(fout, "goto L" + to_string(branchIndex + 1));
              dual_write(fout, "L" + to_string(branchIndex) + ":");
              dual_write(fout, "iconst_1");
              dual_write(fout, "L" + to_string(branchIndex + 1) + ":");
              branchIndex += 2;

              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_GE expression {
              Trace("expression RL_GE expression:");

              // set bytecode whatever type check
              dual_write(fout, "isub");
              dual_write(fout, "ifge L" + to_string(branchIndex));
              dual_write(fout, "iconst_0");
              dual_write(fout, "goto L" + to_string(branchIndex + 1));
              dual_write(fout, "L" + to_string(branchIndex) + ":");
              dual_write(fout, "iconst_1");
              dual_write(fout, "L" + to_string(branchIndex + 1) + ":");
              branchIndex += 2;

              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_GT expression {
              Trace("expression RL_GT expression:");

              // set bytecode whatever type check
              dual_write(fout, "isub");
              dual_write(fout, "ifgt L" + to_string(branchIndex));
              dual_write(fout, "iconst_0");
              dual_write(fout, "goto L" + to_string(branchIndex + 1));
              dual_write(fout, "L" + to_string(branchIndex) + ":");
              dual_write(fout, "iconst_1");
              dual_write(fout, "L" + to_string(branchIndex + 1) + ":");
              branchIndex += 2;

              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_EQ expression {
              Trace("expression RL_EQ expression:");

              // set bytecode whatever type check
              dual_write(fout, "isub");
              dual_write(fout, "ifeq L" + to_string(branchIndex));
              dual_write(fout, "iconst_0");
              dual_write(fout, "goto L" + to_string(branchIndex + 1));
              dual_write(fout, "L" + to_string(branchIndex) + ":");
              dual_write(fout, "iconst_1");
              dual_write(fout, "L" + to_string(branchIndex + 1) + ":");
              branchIndex += 2;

              if (($1 >= 0 && $1 <= 4) && ($3 >=0 && $3 <= 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_NE expression {
              Trace("expression RL_NE expression:");

              // set bytecode whatever type check
              dual_write(fout, "isub");
              dual_write(fout, "ifne L" + to_string(branchIndex));
              dual_write(fout, "iconst_0");
              dual_write(fout, "goto L" + to_string(branchIndex + 1));
              dual_write(fout, "L" + to_string(branchIndex) + ":");
              dual_write(fout, "iconst_1");
              dual_write(fout, "L" + to_string(branchIndex + 1) + ":");
              branchIndex += 2;

              if (($1 >= 0 && $1 <= 4) && ($3 >=0 && $3 <= 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression PLUS expression {
              Trace("expression PLUS expression:");

              // set bytecode whatever type check
              dual_write(fout, "iadd");

              if (($1 == 2 || $1 == 3 || $1 == 4 || $1 == 0) && ($3 == 2 || $3 == 3 || $3 == 4 || $3 == 0)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value or non-string.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression MINU expression {
              Trace("expression MINU expression:");

              // set bytecode whatever type check
              dual_write(fout, "isub");

              if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression MULT expression {
              Trace("expression MULT expression:");

              // set bytecode whatever type check
              dual_write(fout, "imul");

              if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression DIVI expression {
              Trace("expression DIVI expression:");

              // set bytecode whatever type check
              dual_write(fout, "idiv");

              if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      yyerror("left-side data type not equal with right-side data type.");
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | expression REMA expression {
              Trace("expression REMA expression:");

              // set bytecode whatever type check
              dual_write(fout, "irem");

              if ($1 == 2 && $3 == 2){
                  $$ = $1;
              }
              else {
                  yyerror("can't use on non-integer.");
                  $$ = TYPE_ERROR;
              }
          }
          | MINU expression %prec U_MINU {
              Trace("MINU expression %prec U_MINU:");

              // set bytecode whatever type check
              dual_write(fout, "ineg");

              if ($2 == 2 || $2 == 3){
                  $$ = $2;
              }
              else {
                  yyerror("can't use on non-num-value.");
                  $$ = TYPE_ERROR;
              }
          }
          | PARE_L expression PARE_R { $$ = $2; }
          | INTEGER_VAL { $$ = 2; dual_write(fout, "sipush " + to_string($1)); }
          | REAL_VAL { $$ = 3; }
          | CHAR_VAL { $$ = 4; }
          | STRING_VAL { $$ = 0; dual_write(fout, "ldc \"" + adjustStr(string($1)) + "\""); }
          | boolean_value { 
              $$ = 1; 
              if ($1) {
                  dual_write(fout, "iconst_1");
              }
              else {
                  dual_write(fout, "iconst_0");
              }
          }
          | IDENT {
                Trace("expression: IDENT:");
                nowIdent = nowScope->lookup($1, true);
                Trace($1);
                if (nowIdent == NULL) {
                    yyerror(string($1) + " not declared.");
                    $$ = TYPE_ERROR;
                }
                else {
                    Trace(to_string(nowIdent->type));

                    // set bytecode whatever type check
                    dual_write(fout, nowIdent->accessBC);

                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= BOOL_VAR) {
                        $$ = nowIdent->type % TYPE_COUNT;
                    }
                    else {
                        yyerror(string($1) + " not constant or variable.");
                        $$ = TYPE_ERROR;
                    }
                }
          }
          | function_invocation { $$ = $1; }
          | array_reference { $$ = $1; };

function_invocation: IDENT PARE_L option_comma_separated_expressions PARE_R { 
                        Trace("function_invocation:");
                        nowIdent = nowScope->lookup($1, true);
                        if (nowIdent == NULL) {
                            yyerror(string($1) + " not declared.");
                            $$ = TYPE_ERROR;
                        }
                        else {
                            // set bytecode whatever type check
                            dual_write(fout, nowIdent->accessBC);

                            if (nowIdent->type >= METHOD_TYPE_INTEGER && nowIdent->type <= METHOD_TYPE_BOOL) {
                                $$ = nowIdent->type % TYPE_COUNT;
                            }
                            else {
                                yyerror(string($1) + " not return-value method.");
                                $$ = TYPE_ERROR;
                            }
                            Trace("nowIdent->name " + nowIdent->name + to_string(nowIdent->args.size()) + " " + to_string(para.size()));
                            if (nowIdent->args.size() > para.size()) {
                                yyerror("Few arguments in " + string($1) +".");
                            }
                            else if (nowIdent->args.size() < para.size()) {
                                yyerror("Over arguments in " + string($1) +".");
                            }
                            else {
                                bool typeCheck = true;
                                for (int i = 0; i < para.size(); i++) {
                                    Trace("typeCheck " + to_string(i) + " : " + to_string(nowIdent->args[i]) + " " + to_string(para[i]));
                                    if (nowIdent->args[i] % TYPE_COUNT != para[i]) {
                                        typeCheck = false;
                                        break;
                                    }
                                }
                                if (!typeCheck) {
                                    yyerror(string($1) + " argument type check error.");
                                }
                            }
                        }
                    }
                    ;

option_comma_separated_expressions: /* empty */ | { para.clear(); } comma_separated_expressions;

comma_separated_expressions: comma_separated_expression 
                           | comma_separated_expression COMM comma_separated_expressions
                           ;

comma_separated_expression: expression {
                                para.push_back($1);
                            }
                            ;

array_reference: IDENT SQUE_L integer_expression SQUE_R {
                    Trace("array_reference:");

                    // warning array
                    yyerror("Array not supported in this program.", linenum - 1);

                    // still check grammar
                    nowIdent = nowScope->lookup($1, true);
                    if (nowIdent == NULL) {
                        yyerror(string($1) + " not declared.");
                        $$ = TYPE_ERROR;
                    }
                    else {
                        if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                            yyerror(string($1) + " is constant, not array.");
                            $$ = TYPE_ERROR;
                        }
                        else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                            $$ = nowIdent->type % TYPE_COUNT;
                        }
                        else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                            yyerror(string($1) + " is function, not array.");
                            $$ = TYPE_ERROR;
                        }
                        else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                            yyerror(string($1) + " is variable, not array.");
                            $$ = TYPE_ERROR;
                        }
                        else {
                            yyerror(string($1) + " occur unknow error.");
                            $$ = TYPE_ERROR;
                        }
                    }
                }
                ; 

integer_expression: expression { 
                        Trace("integer_expression:");
                        if ($1 != 2) {
                            yyerror("This expression not integer.");
                        }
                  }
                  ;

boolean_expression: expression {
                        Trace("boolean_expression:");
                        if ($1 != 1) {
                            yyerror("This expression not boolean.");
                        } 
                  }
                  ; 
%%
int main(int argc, char *argv[])
{
    /* open the source program file */
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <filename>" << std::endl;
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    filename = string(argv[1]);

    rawname = filename.substr(0, filename.find_last_of("."));
    fout.open(rawname + ".jasm");

    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error!");     /* syntax error */
}