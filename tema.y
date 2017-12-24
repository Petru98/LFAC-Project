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
%token INT_CONSTANT FLOAT_CONSTANT CHAR_CONSTANT STRING_LITERAL



/******************************************************************************/
/*********************************** Rules ************************************/
/******************************************************************************/
%%
Pgm : ;

Const  : INT_CONSTANT
       | FLOAT_CONSTANT
       | CHAR_CONSTANT
       | STRING_LITERAL
       ;
Consts : Const
       | Const Const
       ;

Ids : ID
    | ID ID
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
