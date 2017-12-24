/******************************************************************************/
/******************************** Declarations ********************************/
/******************************************************************************/

/* C code */
%{
#include <stdio.h>
#include <stdint.h>

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
%token TypeInt TypeFloat TypeChar TypeString
%token Id
%token Int Float Char String



/******************************************************************************/
/*********************************** Rules ************************************/
/******************************************************************************/
%%
Pgm : ;

Const  : Int
       | Float
       | Char
       | String
       ;
Consts : Const
       | Const Const
       ;

Ids : Id
    | Id Id
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
