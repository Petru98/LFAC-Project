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
%left '+' '-'
%left '*' '/' '%'
%left '('')'



/******************************************************************************/
/*********************************** Rules ************************************/
/******************************************************************************/
%%
Pgm :
    | Stmts
    ;



Exp :
    ;



Stmt  : DeclVar ';'
      ;
Stmts : Stmt
      | Stmt Stmt
      ;



DeclVar : TypeVar ID
        ;


TypeVar : INT
        | BOOL
        | FLOAT
        | STRING
        | CHAR

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
