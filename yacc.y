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

#include "lex.yy.c"

using namespace std;

symbolTable* nowScope;
symbolTable* fatherScope;
ident* nowIdent;
vector<int> para;
bool legalMethod = true;
string filename = "";

void yyerror(std::string msg) {
    std::cerr << BOLDYELLOW << filename << ":" << linenum << ": warning: " << BOLDWHITE << msg << RESET << std::endl;
}

void yyerror(std::string msg, int customLinenum) {
    std::cerr << BOLDYELLOW << filename << ":" << customLinenum << ": warning: " << BOLDWHITE << msg << RESET << std::endl;
}

%}
%union {
    int intVal;
    char* strVal;
    float realVal;
    char charVal;
}
/* tokens */
%token INTEGER_VAL REAL_VAL CHAR_VAL STRING_VAL
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

%type <intVal> types
%type <intVal> option_types
%type <intVal> option_assign_value

%type <intVal> expression
%type <intVal> function_invocation
%type <intVal> integer_expression
%type <intVal> boolean_expression
%type <intVal> const_expression
%type <intVal> array_reference

%%
program: object_;

object_: OBJECT IDENT BRAC_L { 
            Trace("object_: create new symbolTable.");
            nowScope = new symbolTable($2, NULL); 
         }
         object_inside_statements BRAC_R {
             nowIdent = nowScope->lookup("main", false);
             if (nowIdent == NULL) {
                 yyerror("object need a main entry method.", 0);
             } 
             else if (nowIdent->type < METHOD_TYPE_FUNC || nowIdent->type > METHOD_TYPE_BOOL) {
                 yyerror("identifier main need to set as method-type", 0);
             }
         };

object_inside_statements: /* empty */
                        | object_inside_statement object_inside_statements;

object_inside_statement: var_const_declaration 
                       | method_declartion
                       ;

// var_const_declarations: /* empty */
//                         | var_const_declaration var_const_declarations ;

var_const_declaration: VAL const_declaration
                    |  VAR var_declaration;

const_declaration: IDENT option_types ASSI const_expression { 
                    Trace("const_declaration:");
                    if (nowScope->lookup($1, false) == NULL) {
                        if ($2 != TYPE_NOT_DEFINE) {
                            if ($2 == $4) {
                                nowScope->insert($1, CONST_INTEGER + $2);
                            }
                            else {
                                yyerror("Constant declartion type not equal with value type.", linenum - 1);
                            }
                        }
                        else {
                            nowScope->insert($1, CONST_INTEGER + $4);
                        }
                    }
                    else {
                        string msg = string($1) + " already declared.";
                        yyerror(msg, linenum - 1);
                    }
                 }
                 ;

option_types: /* empty */ { $$ = TYPE_NOT_DEFINE; }
            | COLO types { $$ = $2; }
            ;

types: 
       INT { $$ = 0; }
     | REAL { $$ = 1; }
     | CHAR { $$ = 2; }
     | STRING { $$ = 3; }
     | BOOLEAN { $$ = 4; }
     ;

const_expression: 
                  INTEGER_VAL { $$ = 0; }
                | REAL_VAL { $$ = 1; }
                | CHAR_VAL { $$ = 2; }
                | STRING_VAL { $$ = 3; }
                | boolean_value { $$ = 4; }
                ;

boolean_value: TRUE | FALSE;

var_declaration: IDENT option_types option_assign_value { 
                    Trace("var_declaration:");
                    if (nowScope->lookup($1, false) == NULL) {
                        if ($2 != TYPE_NOT_DEFINE && $3 != TYPE_NOT_DEFINE) {
                            if ($2 == $3) {
                                nowScope->insert($1, INTEGER_VAR + $2);
                            }
                            else {
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
                    }
                    else {
                        string msg = string($1) + " already declared.";
                        yyerror(msg, linenum - 1);
                    }
               }
               | array_declartion
               ;

option_assign_value: /* empty */ { $$ = TYPE_NOT_DEFINE; }
                   | ASSI const_expression { $$ = $2; }
                   ;

array_declartion: IDENT COLO types SQUE_L INTEGER_VAL SQUE_R { 
                    Trace("array_declartion:");
                    if (nowScope->lookup($1, false) == NULL) {
                        nowScope->insert($1, INTEGER_ARRAY + $3); 
                    }
                    else {
                        string msg = string($1) + " already declared.";
                        yyerror(msg, linenum - 1);
                    }
                } 
                ;

// method_declartions: method_declartion 
//                   | method_declartion method_declartions;

method_declartion: DEF IDENT { 
                    Trace("method_declartion:");
                    if (nowScope->lookup($2, false) == NULL) {
                        legalMethod = true;
                        nowScope->insert($2, METHOD_TYPE_NOT_DEFINE); 
                        nowIdent = nowScope->lookup($2, false);
                        nowScope = nowScope->createChild($2); 
                    }
                    else {
                        legalMethod = false;
                        string msg = string($2) + " already declared.";
                        yyerror(msg);

                        nowScope = nowScope->createChild("temp_method"); 
                    }
                } 
                PARE_L option_method_formal_arguments PARE_R option_method_return_type 
                block {
                    fatherScope = nowScope->fatherTable;
                    delete nowScope;
                    nowScope = fatherScope;
                };
                
option_method_formal_arguments: /* empty */ 
                              | method_formal_arguments;

method_formal_arguments: method_formal_argument 
                       | method_formal_argument COMM method_formal_arguments;

method_formal_argument: IDENT COLO types { 
                            Trace("method_formal_argument:");
                            if (legalMethod) {
                                nowIdent->addParam(INTEGER_VAR + $3);
                                string trace_msg = "size: " + to_string(nowIdent->args.size());
                                Trace(trace_msg);
                            }
                            nowScope->insert($1, INTEGER_VAR + $3);
                        }
                        ;

option_method_return_type: /* empty */ { 
                            if (legalMethod) {
                                nowIdent->type = METHOD_TYPE_FUNC;
                            }
                            nowScope->returnType = METHOD_TYPE_FUNC;
                         }
                         | COLO types { 
                            if (legalMethod) {
                                nowIdent->type = METHOD_TYPE_INTEGER + $2;
                            } 
                            nowScope->returnType = METHOD_TYPE_INTEGER + $2;
                         }
                         ;

block: { Trace("block:"); } BRAC_L block_inside_statements BRAC_R;

block_inside_statements: /* empty */
                       | block_inside_statement block_inside_statements
                       ;

block_inside_statement: var_const_declaration | statement;

// statements: /* empty */ 
//           | { Trace("statement:"); } statement statements;

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
                nowIdent = nowScope->lookup($1, true);
                if (nowIdent == NULL) {
                    string msg = string($1) + " not declared.";
                    yyerror(msg, linenum - 1);
                }
                else {
                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                        string msg = string($1) + " is constant, can't reassign.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                        string msg = string($1) + " is array, can't assign value.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                        string msg = string($1) + " is function, can't assign value.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                        if (nowIdent->type % TYPE_COUNT != $3) {
                            string msg = string($1) + " data type not correct, can't assign value.";
                            yyerror(msg, linenum - 1);
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
                        string msg = string($1) + " occur unknow error.";
                        yyerror(msg, linenum - 1);
                    }
                }
           }
           ;

statement_2: IDENT SQUE_L integer_expression SQUE_R ASSI expression {
                Trace("statement_2:");
                nowIdent = nowScope->lookup($1, true);
                if (nowIdent == NULL) {
                    string msg = string($1) + " not declared.";
                    yyerror(msg, linenum - 1);
                }
                else {
                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                        string msg = string($1) + " is constant, not array.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                        if (nowIdent->type % TYPE_COUNT != $6) {
                            string msg = string($1) + " data type not correct, can't assign value.";
                            yyerror(msg, linenum - 1);
                        }
                    }
                    else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                        string msg = string($1) + " is function, not array.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                        string msg = string($1) + " is variable, not array.";
                        yyerror(msg, linenum - 1);
                    }
                    else {
                        string msg = string($1) + " occur unknow error.";
                        yyerror(msg, linenum - 1);
                    }
                }
            }
            ;

statement_3: PRINT PARE_L expression PARE_R { 
                Trace("statement_3:");
                if ($3 <= METHOD_TYPE_FUNC && $3 > BOOL_VAR) {
                    yyerror("This expression can't print.", linenum - 1);
                }
           }
           | PRINTLN PARE_L expression PARE_R { 
                Trace("statement_3:");
                if ($3 <= METHOD_TYPE_FUNC && $3 > BOOL_VAR) {
                    yyerror("This expression can't print.", linenum - 1);
                }
           }
           ;

statement_4: READ IDENT {
                Trace("statement_4:");
                nowIdent = nowScope->lookup($2, true);
                if (nowIdent == NULL) {
                    string msg = string($2) + " not declared.";
                    yyerror(msg, linenum - 1);
                }
                else {
                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                        string msg = string($2) + " is constant, can't reassign.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                        string msg = string($2) + " is array, can't assign.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                        string msg = string($2) + " is function, can't assign.";
                        yyerror(msg, linenum - 1);
                    }
                    else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                        string msg = string($2) + " is variable, can reassign.";
                    }
                    else if (nowIdent->type == TYPE_NOT_DEFINE) {
                        string msg = string($2) + " is non define type variable, can assign.";
                    }
                    else {
                        string msg = string($2) + " occur unknow error.";
                        yyerror(msg, linenum - 1);
                    }
                }
           }
           ;

statement_5: RETURN {
                Trace("statement_5: RETURN");
                symbolTable* temp_scope = nowScope;
                while (temp_scope->returnType == NON_TYPE) {
                    if (temp_scope->fatherTable == NULL) {
                        break;
                    }
                    temp_scope = temp_scope->fatherTable;
                }
                Trace("Return scope name:" + temp_scope->scopeName);
                if (temp_scope->returnType != METHOD_TYPE_FUNC) {
                    if (temp_scope->returnType >= METHOD_TYPE_INTEGER && temp_scope->returnType <= METHOD_TYPE_BOOL) {
                        string msg = temp_scope->scopeName + " need return value.";
                        yyerror(msg, linenum - 1);
                    }
                    else {
                        string msg = "Don't do return in non-method scope.";
                        yyerror(msg, linenum - 1);
                    }
                }
            }
           | RETURN expression { 
                Trace("statement_5: RETURN expression");
                symbolTable* temp_scope = nowScope;
                while (temp_scope->returnType == NON_TYPE) {
                    if (temp_scope->fatherTable == NULL) {
                        break;
                    }
                    temp_scope = temp_scope->fatherTable;
                }
                Trace("Return scope name:" + temp_scope->scopeName);
                if (temp_scope->returnType >= METHOD_TYPE_INTEGER && temp_scope->returnType <= METHOD_TYPE_BOOL) {
                    if (temp_scope->returnType % TYPE_COUNT != $2) {
                        string msg = "Return type error.";
                        yyerror(msg, linenum - 1);
                    }
                }
                else {
                    if (temp_scope->returnType == METHOD_TYPE_FUNC) {
                        string msg = temp_scope->scopeName + " no need return value.";
                        yyerror(msg, linenum - 1);
                    }
                    else {
                        string msg = "Don't do return in non-method scope.";
                        yyerror(msg, linenum - 1);
                    }
                }
            }
           ;

conditional_statement: { Trace("conditional_statement:"); } IF PARE_L boolean_expression PARE_R block_or_simple_statement option_else_statement;

block_or_simple_statement: {
                               Trace("block_or_simple_statement:");
                               nowScope = nowScope->createChild("temp_block"); 
                           } block {
                               fatherScope = nowScope->fatherTable;
                               delete nowScope;
                               nowScope = fatherScope;
                           } 
                           | statement;

option_else_statement: /* empty */ | ELSE block_or_simple_statement;

while_loop_statement: { Trace("while_loop_statement:"); } WHILE PARE_L boolean_expression PARE_R block_or_simple_statement;

for_loop_statement: FOR PARE_L IDENT {
                        Trace("for_loop_statement:");
                        nowIdent = nowScope->lookup($3, true);
                        if (nowIdent == NULL) {
                            string msg = string($3) + " not declared.";
                            yyerror(msg);
                        }
                        else if (nowIdent->type != INTEGER_VAR) {
                            string msg = string($3) + " not integer.";
                            yyerror(msg);
                        }
                    }
                    ARRO INTEGER_VAL TO INTEGER_VAL PARE_R block_or_simple_statement;

procedure_invocation: IDENT | IDENT PARE_L comma_separated_expressions PARE_R;

expression: expression LG_OR expression {
              Trace("expression LG_OR expression:");
              if ($1 == 1 && $3 == 1){
                  $$ = $1;
              }
              else {
                  string msg = "can't use on non-boolean.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression LG_AND expression {
              Trace("expression LG_AND expression:");
              if ($1 == 1 && $3 == 1){
                  $$ = $1;
              }
              else {
                  string msg = "can't use on non-boolean.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression LG_NOT expression {
              Trace("expression LG_NOT expression:");
              if ($1 == 1 && $3 == 1){
                  $$ = $1;
              }
              else {
                  string msg = "can't use on non-boolean.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_LT expression {
              Trace("expression RL_LT expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_LE expression {
              Trace("expression RL_LE expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_GE expression {
              Trace("expression RL_GE expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_GT expression {
              Trace("expression RL_GT expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_EQ expression {
              Trace("expression RL_EQ expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression RL_NE expression {
              Trace("expression RL_NE expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4) && ($3 == 2 || $3 == 3 || $3 == 4)) {
                  if ($1 == $3) {
                      $$ = 1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression PLUS expression {
              Trace("expression PLUS expression:");
              if (($1 == 2 || $1 == 3 || $1 == 4 || $1 == 0) && ($3 == 2 || $3 == 3 || $3 == 4 || $3 == 0)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value or non-string.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression MINU expression {
              Trace("expression MINU expression:");
              if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression MULT expression {
              Trace("expression MULT expression:");
              if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression DIVI expression {
              Trace("expression DIVI expression:");
              if (($1 == 2 || $1 == 3) && ($3 == 2 || $3 == 3)) {
                  if ($1 == $3) {
                      $$ = $1;
                  }
                  else {
                      string msg = "left-side data type not equal with right-side data type.";
                      yyerror(msg);
                      $$ = TYPE_ERROR;
                  }  
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | expression REMA expression {
              Trace("expression REMA expression:");
              if ($1 == 2 && $3 == 3){
                  $$ = $1;
              }
              else {
                  string msg = "can't use on non-integer.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | MINU expression %prec U_MINU {
              Trace("MINU expression %prec U_MINU:");
              if ($2 == 2 || $2 == 3){
                  $$ = $2;
              }
              else {
                  string msg = "can't use on non-num-value.";
                  yyerror(msg);
                  $$ = TYPE_ERROR;
              }
          }
          | PARE_L expression PARE_R { $$ = $2; }
          | INTEGER_VAL { $$ = 2; }
          | REAL_VAL { $$ = 3; }
          | CHAR_VAL { $$ = 4; }
          | STRING_VAL { $$ = 0;}
          | boolean_value { $$ = 1; }
          | IDENT {
                Trace("expression: IDENT:");
                nowIdent = nowScope->lookup($1, true);
                if (nowIdent == NULL) {
                    string msg = string($1) + " not declared.";
                    yyerror(msg);
                    $$ = TYPE_ERROR;
                }
                else {
                    if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= BOOL_VAR) {
                        $$ = nowIdent->type % TYPE_COUNT;
                    }
                    else {
                        string msg = string($1) + " not constant or variable.";
                        yyerror(msg);
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
                            string msg = string($1) + " not declared.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }
                        else {
                            if (nowIdent->type >= METHOD_TYPE_INTEGER && nowIdent->type <= METHOD_TYPE_BOOL) {
                                $$ = nowIdent->type % TYPE_COUNT;
                            }
                            else {
                                string msg = string($1) + " not return-value method.";
                                yyerror(msg);
                                $$ = TYPE_ERROR;
                            }
                        }
                        string trace_msg = "nowIdent->name " + nowIdent->name + to_string(nowIdent->args.size()) + " " + to_string(para.size());
                        Trace(trace_msg);
                        if (nowIdent->args.size() > para.size()) {
                            string msg = "Few arguments in " + string($1) +".";
                            yyerror(msg);
                        }
                        else if (nowIdent->args.size() < para.size()) {
                            string msg = "Over arguments in " + string($1) +".";
                            yyerror(msg);
                        }
                        else {
                            bool typeCheck = true;
                            for (int i = 0; i < para.size(); i++) {
                                string trace_msg = "typeCheck " + to_string(i) + " : " + to_string(nowIdent->args[i]) + " " + to_string(para[i]);
                                Trace(trace_msg);
                                if (nowIdent->args[i] % TYPE_COUNT != para[i]) {
                                    typeCheck = false;
                                    break;
                                }
                            }
                            if (!typeCheck) {
                                string msg = string($1) + " argument type check error.";
                                yyerror(msg);
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
                    nowIdent = nowScope->lookup($1, true);
                    if (nowIdent == NULL) {
                        string msg = string($1) + " not declared.";
                        yyerror(msg);
                        $$ = TYPE_ERROR;
                    }
                    else {
                        if (nowIdent->type >= CONST_INTEGER && nowIdent->type <= CONST_BOOL) {
                            string msg = string($1) + " is constant, not array.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }
                        else if (nowIdent->type >= INTEGER_ARRAY && nowIdent->type <= BOOL_ARRAY) {
                            $$ = nowIdent->type % TYPE_COUNT;
                        }
                        else if (nowIdent->type >= METHOD_TYPE_FUNC && nowIdent->type <= METHOD_TYPE_BOOL) {
                            string msg = string($1) + " is function, not array.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }
                        else if (nowIdent->type >= INTEGER_VAR && nowIdent->type <= BOOL_VAR) {
                            string msg = string($1) + " is variable, not array.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }
                        else {
                            string msg = string($1) + " occur unknow error.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }
                    }
                }
                ; 

integer_expression: expression { 
                        Trace("integer_expression:");
                        if ($1 == 2) {
                            $$ = $1;
                        }
                        else {
                            string msg = "This expression not integer.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }
                  }
                  ;

boolean_expression: expression {
                        Trace("boolean_expression:");
                        if ($1 == 1) {
                            $$ = $1;
                        }
                        else {
                            string msg = "This expression not boolean.";
                            yyerror(msg);
                            $$ = TYPE_ERROR;
                        }    
                  }
                  ; 
%%
int main(int argc, char *argv[])
{
    /* open the source program file */
    if (argc != 2) {
        printf ("Usage: parser filename\n");
        exit(1);
    }
    yyin = fopen(argv[1], "r");         /* open input file */
    filename = string(argv[1]);

    /* perform parsing */
    if (yyparse() == 1)                 /* parsing */
        yyerror("Parsing error!");     /* syntax error */
}