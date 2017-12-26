/******************************************************************************/
/******************************** Declarations ********************************/
/******************************************************************************/

/* C code */
%{
#include <stdio.h>
#include <stdint.h>
#include "String.h"

extern int yylineno;
void yyerror(const char* msg);
void yywarning(const char* msg);
int yylex();

#define YYLTYPE yyltype
typedef struct yyltype
{
    size_t first_line;
    size_t first_column;
    size_t last_line;
    size_t last_column;
} yyltype;
%}

/* Flags for yacc */
%defines
%locations

/* Tokens */
%start Pgm
%token INT BOOL FLOAT CHAR STRING VOID IF WHILE FOR CLASS
%token ID
%token INT_CONSTANT BOOL_CONSTANT FLOAT_CONSTANT CHAR_CONSTANT STRING_LITERAL
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN INC_OP DEC_OP AND_OP OR_OP EQ_OP NE_OP LE_OP GE_OP PTR_OP

/* Precedence */
%left AND_OP OR_OP
%nonassoc EQ_OP NE_OP LE_OP GE_OP '<' '>'
%nonassoc '='
%left ','
%left '+' '-'
%left '*' '/' '%'
%nonassoc '!'
%nonassoc INC_OP DEC_OP
%left '('')'



/******************************************************************************/
/*********************************** Rules ************************************/
/******************************************************************************/
%%
Pgm :
    | Stmts
    ;



Stmts : Stmt
      | Stmt Stmt
      ;
Stmt  : ';'
      | DeclVar ';'
      | Exp ';'
      | '{' Stmt '}'
      ;



Exp  : ID
     | ID '=' Exp
     | ID '('  ')'

     | INT_CONSTANT
     | BOOL_CONSTANT
     | FLOAT_CONSTANT
     | CHAR_CONSTANT

     | INC_OP Exp
     | DEC_OP Exp
     | Exp INC_OP
     | Exp DEC_OP

     | Exp '+' Exp
     | Exp '-' Exp
     | Exp '*' Exp
     | Exp '/' Exp
     | Exp '%' Exp
     | '-' Exp      %prec ','

     | '!' Exp
     | Exp AND_OP Exp
     | Exp OR_OP  Exp

     | Exp EQ_OP Exp
     | Exp NE_OP Exp
     | Exp LE_OP Exp
     | Exp GE_OP Exp
     | Exp  '<'  Exp
     | Exp  '>'  Exp

     | '(' Exp ')'
     ;



DeclVar : TypeVar InitVarList
        ;

TypeVar : INT
        | BOOL
        | FLOAT
        | STRING
        | CHAR

InitVarList : InitVar
            | InitVar ',' InitVarList
            ;
InitVar     : ID
            | ID '=' Exp
            ;

Const  : INT_CONSTANT
       | BOOL_CONSTANT
       | FLOAT_CONSTANT
       | CHAR_CONSTANT
       | STRING_LITERAL
       ;



%%
/******************************************************************************/
/*********************************** C code ***********************************/
/******************************************************************************/
int main(int argc, char** argv)
{
    yyparse();
    return 0;
}
