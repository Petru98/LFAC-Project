/******************************************************************************/
/******************************** Declarations ********************************/
/******************************************************************************/

/* C code */
%code requires
{
#include "util.h"
}

%{
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include "util.h"

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

extern FILE* yyin;
extern int scope_level;



VariableList varlist = {0};
FunctionList funclist = {0};

void declareVariable(const char* name, int type, bool constant, void* data);
%}

/* Flags for yacc */
%defines
%locations
%yacc

%union
{
    long intval;
    bool boolval;
    double doubleval;
    char charval;
    char* strval;
    char* idval;
}

/* Tokens */
%start Pgm
%token <intval> INT BOOL DOUBLE CHAR STRING VOID
%token CONST PRINT IF ELSE WHILE DO FOR RETURN CLASS THIS PUBLIC PRIVATE

%token <idval> ID
%token <intval> INT_CONSTANT
%token <boolval> BOOL_CONSTANT
%token <doubleval> DOUBLE_CONSTANT
%token <charval> CHAR_CONSTANT
%token <strval> STRING_LITERAL

%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN INC_OP DEC_OP AND_OP OR_OP EQ_OP NE_OP LE_OP GE_OP

/* Precedence */
%left ','
%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
%left AND_OP OR_OP
%nonassoc EQ_OP NE_OP LE_OP GE_OP '<' '>'
%left '+' '-'
%left '*' '/' '%'
%nonassoc '!'
%nonassoc INC_OP DEC_OP
%left '.' '['']' '('')'

%nonassoc NOELSE
%nonassoc ELSE



/******************************************************************************/
/*********************************** Rules ************************************/
/******************************************************************************/
%%
Pgm :
    | Stmts
    ;



Stmts : Stmt
      | Stmts Stmt
      ;

Stmt  : ';'
      | DeclVar ';'
      | DeclFunc
      | DeclClass
      | Exp ';'
      | '{' Stmts '}'
      | '{'       '}'

      | PRINT '(' Exp ')' ';'
      | RETURN Exp ';'

      | IF '(' Exp ')' Stmt           %prec NOELSE
      | IF '(' Exp ')' Stmt ELSE Stmt

      | WHILE '(' Exp ')' Stmt
      | DO Stmt WHILE '(' Exp ')' ';'

      | FOR '(' ForInitExp ';' ForCondExp ';' ForNextExp ')' Stmt
      ;



ForInitExp :
           | Exp
           | DeclVar
           ;
ForCondExp :
           | Exp
           ;
ForNextExp :
           | Exp
           ;



Exp  : VarAccess
     | VarAccess '=' Exp
     | FuncCall

     | INT_CONSTANT
     | BOOL_CONSTANT
     | DOUBLE_CONSTANT
     | CHAR_CONSTANT

     | INC_OP VarAccess
     | DEC_OP VarAccess
     | VarAccess INC_OP
     | VarAccess DEC_OP

     | VarAccess ADD_ASSIGN Exp
     | VarAccess SUB_ASSIGN Exp
     | VarAccess MUL_ASSIGN Exp
     | VarAccess DIV_ASSIGN Exp
     | VarAccess MOD_ASSIGN Exp

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



TypePredef : INT
           | BOOL
           | DOUBLE
           | CHAR
           | STRING
           ;



/************************/
/* Variable declaration */
/************************/


DeclVar       : TypePredef ID               {void* val = 0; declareVariable($2, $<intval>1, false, &val); free($2);}
              | TypePredef ID ArrayDeclSize {void* val = 0; declareVariable($2, $<intval>1, false, &val); free($2);}
              | TypePredef ID '=' Exp       {declareVariable($2, $<intval>1, false, &$<strval>4); free($2);}

              | ID ID               {declareVariable($2, CLASS, false, &$1); free($1); free($2);}
              | ID ID ArrayDeclSize {declareVariable($2, CLASS, false, &$1); free($1); free($2);}
              | ID ID '=' Exp       {declareVariable($2, CLASS, false, &$<strval>4); free($1); free($2);}

              | CONST TypePredef ID '=' Exp {declareVariable($3, $<intval>2, true, &$<strval>5); free($3);}
              ;

ArrayDeclSize : '[' ConstIntExp ']'
              | '[' ConstIntExp ']' ArrayDeclSize
              ;



/************************/
/* Function declaration */
/************************/

DeclFunc              : TypePredef ID '(' DeclParamList ')' '{' Stmts '}' {free($2);}
                      | ID         ID '(' DeclParamList ')' '{' Stmts '}' {free($1); free($2);}
                      | VOID       ID '(' DeclParamList ')' '{' Stmts '}' {free($2);}
                      ;

DeclParamList         :
                      | DeclParamListNonEmpty
                      ;

DeclParamListNonEmpty : DeclParam
                      | DeclParamListNonEmpty ',' DeclParam
                      ;

DeclParam             : TypePredef ID {free($2);}
                      | ID ID         {free($1); free($2);}
                      ;



/*********************/
/* Class declaration */
/*********************/

AccessModifier   : PUBLIC
                 | PRIVATE
                 ;

DeclClass        : CLASS ID '{' DeclClassMembers '}' {free($2);}
                 ;

DeclClassMembers : DeclClassMember
                 | DeclClassMembers DeclClassMember
                 ;

DeclClassMember  : AccessModifier DeclVar ';'
                 | AccessModifier DeclFunc
                 ;



/*******************/
/* Variable access */
/*******************/

VarAccess       : NormalVarAccess
                | THIS
                | THIS '.' NormalVarAccess
                ;

NormalVarAccess : ID                                   {free($1);}
                | ID '.' NormalVarAccess               {free($1);}
                | ID ArrayIndexing                     {free($1);}
                | ID ArrayIndexing '.' NormalVarAccess {free($1);}
                ;

ArrayIndexing   : '[' Exp ']'
                | '[' Exp ']' ArrayIndexing
                ;



/*****************/
/* Function call */
/*****************/

FuncCall         : VarAccess '(' FuncParamExpList ')'
                 ;

FuncParamExpList :
                 | Exp
                 | FuncParamExpList ',' Exp
                 ;



/*************/
/* Constants */
/*************/

ConstIntExp : INT_CONSTANT

            | ConstIntExp '+' ConstIntExp
            | ConstIntExp '-' ConstIntExp
            | ConstIntExp '*' ConstIntExp
            | ConstIntExp '/' ConstIntExp
            | ConstIntExp '%' ConstIntExp

            | '-' ConstIntExp     %prec ','
            | '(' ConstIntExp ')'
            ;



%%
/******************************************************************************/
/*********************************** C code ***********************************/
/******************************************************************************/
void handleSIGSEGV(int s)
{
    yyerror("SIGSEGV caught... aborting");
    abort();
}

int main(int argc, char** argv)
{
    signal(SIGSEGV, handleSIGSEGV);

    if(argc >= 2)
    {
        FILE* fp = fopen(argv[1], "r");
        if(fp == NULL)
        {
            fprintf(stderr, "could not open file %s\n", argv[1]);
            return 1;
        }

        if((yyin != NULL && fclose(yyin) != 0) || fclose(stdin) != 0)
        {
            fprintf(stderr, "fclose failed\n");
            return 1;
        }

        yyin = fp;
        stdin = yyin;
    }

    yyparse();
    return 0;
}

void declareVariable(const char* name, int type, bool constant, void* data)
{
    const int error = VariableList_insert(&varlist, name, strlen(name), type, scope_level, constant, data);

    if(error == 1)
        yyerror("variable is already declared");
    else if(error == -1)
        yyerror("not enough memory to declare variable");
}
