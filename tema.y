/******************************************************************************/
/******************************** Declarations ********************************/
/******************************************************************************/

/* C code */
%code requires
{
#include "yylloc.h"
#include "util.h"
}

%{
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include "yylloc.h"
#include "util.h"

void yyerror(const char* msg, ...);
void yywarning(const char* msg, ...);
int yylex();

extern FILE* yyin;
int scope_level = 0;

VariableList varlist = {0};
VariableListStack varliststack = {0};

FunctionList funclist = {0};
FunctionListStack funcliststack = {0};

void declareVariable(VariableList* varlist, int scope_level, char* name, int type, bool constant, bool initialized, void* data, const YYLTYPE* yylloc);
void declareFunction(FunctionList* funclist, int scope_level, char* name, const Type* return_type, TypeList* typelist, const YYLTYPE* yylloc);
void enterBlock();
void exitBlock();

void checkIfVariableIsDeclared(const char* name);
void checkIfVariableIsInitialized(const char* name);
%}

/* Flags for yacc */
%defines
%locations
%yacc
//%no-lines // Uncomment to be able to add breakpoints in y.tab.c

%union
{
    long intval;
    bool boolval;
    double doubleval;
    char charval;
    char* strval;
    char* idval;
    Type typeval;
    TypeList typelistval;
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

/* Types for non-terminal */
%type <intval> TypePredef
%type <typeval> DeclParam

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
      | '{' {enterBlock();} Stmts '}' {exitBlock();}
      | '{''}'

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



Exp  : VarAccess         {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}
     | VarAccess '=' Exp {free($<idval>1);}
     | FuncCall

     | INT_CONSTANT
     | BOOL_CONSTANT
     | DOUBLE_CONSTANT
     | CHAR_CONSTANT

     | INC_OP VarAccess {checkIfVariableIsInitialized($<idval>2); free($<idval>2);}
     | DEC_OP VarAccess {checkIfVariableIsInitialized($<idval>2); free($<idval>2);}
     | VarAccess INC_OP {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}
     | VarAccess DEC_OP {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}

     | VarAccess ADD_ASSIGN Exp {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}
     | VarAccess SUB_ASSIGN Exp {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}
     | VarAccess MUL_ASSIGN Exp {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}
     | VarAccess DIV_ASSIGN Exp {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}
     | VarAccess MOD_ASSIGN Exp {checkIfVariableIsInitialized($<idval>1); free($<idval>1);}

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


DeclVar       : TypePredef ID               {long double val = 0; declareVariable(&varlist, scope_level, $2, $<intval>1, false, false, &val, &@2);}
              | TypePredef ID ArrayDeclSize {long double val = 0; declareVariable(&varlist, scope_level, $2, $<intval>1, false, false, &val, &@2);}
              | TypePredef ID '=' Exp       {declareVariable(&varlist, scope_level, $2, $<intval>1, false, true, &$<strval>4, &@2);}

              | ID ID               {declareVariable(&varlist, scope_level, $2, CLASS, false, false, &$1, &@2);}
              | ID ID ArrayDeclSize {declareVariable(&varlist, scope_level, $2, CLASS, false, false, &$1, &@2);}
              | ID ID '=' Exp       {declareVariable(&varlist, scope_level, $2, CLASS, false, true, &$<strval>4, &@2);}

              | CONST TypePredef ID '=' Exp {declareVariable(&varlist, scope_level, $3, $<intval>2, true, true, &$<strval>5, &@3);}
              ;

ArrayDeclSize : '[' ConstIntExp ']'
              | '[' ConstIntExp ']' ArrayDeclSize
              ;



/************************/
/* Function declaration */
/************************/

DeclFunc              : TypePredef ID {enterBlock();} '(' DeclParamList ')' {Type ret_t = {$1,0};     declareFunction(FunctionListStack_top(&funcliststack), scope_level - 1, $2, &ret_t, &$<typelistval>5, &@2);} '{' Stmts '}' {exitBlock();}
                      | ID         ID {enterBlock();} '(' DeclParamList ')' {Type ret_t = {CLASS,$1}; declareFunction(FunctionListStack_top(&funcliststack), scope_level - 1, $2, &ret_t, &$<typelistval>5, &@2);} '{' Stmts '}' {exitBlock();}
                      | VOID       ID {enterBlock();} '(' DeclParamList ')' {Type ret_t = {VOID,0};   declareFunction(FunctionListStack_top(&funcliststack), scope_level - 1, $2, &ret_t, &$<typelistval>5, &@2);} '{' Stmts '}' {exitBlock();}
                      ;

DeclParamList         :                       {$<typelistval>$.elements = NULL; $<typelistval>$.capacity = 0; $<typelistval>$.size = 0;}
                      | DeclParamListNonEmpty
                      ;

DeclParamListNonEmpty : DeclParam                           {$<typelistval>$.elements = NULL; $<typelistval>$.capacity = 0; $<typelistval>$.size = 0; TypeList_insert(&$<typelistval>$, &$1);}
                      | DeclParamListNonEmpty ',' DeclParam {TypeList_insert(&$<typelistval>1, &$3); $<typelistval>$ = $<typelistval>1;}
                      ;

DeclParam             : TypePredef ID {$$.type = $1; $$.class_name = NULL; long double val = 0; declareVariable(&varlist, scope_level, $2, $<intval>1, false, true, &val, &@2);}
                      | ID ID         {$$.type = CLASS; $$.class_name = $1; declareVariable(&varlist, scope_level, $2, CLASS, false, true, &$1, &@2);}
                      ;



/*********************/
/* Class declaration */
/*********************/

AccessModifier   : PUBLIC
                 | PRIVATE
                 ;

DeclClass        : CLASS ID {enterBlock(); char* s = strdup($2); declareVariable(&varlist, scope_level, strdup("this"), CLASS, true, true, &s, &yylloc);} '{' DeclClassMembers '}' {exitBlock();}
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

VarAccess       : ID                  {checkIfVariableIsDeclared($<idval>1);}
                | ID VarAccessExtra   {checkIfVariableIsDeclared($<idval>1);}
                | THIS                {checkIfVariableIsDeclared($<idval>1);}
                | THIS VarAccessExtra {checkIfVariableIsDeclared($<idval>1);}
                ;

VarAccessExtra  : '.' ID                       {free($2);}
                | '.' ID VarAccessExtra        {free($2);}
                | ArrayIndexing                {}
                | ArrayIndexing VarAccessExtra {}
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



void declareVariable(VariableList* varlist, int scope_level, char* name, int type, bool constant, bool initialized, void* data, const YYLTYPE* yylloc)
{
    if(name == NULL)
    {
        yyerror("not enough memory to declare variable");
        abort();
    }

    int insert_position;
    const int current_position = VariableList_find(varlist, name, &insert_position);

    if(current_position >= 0)
    {
        if(varlist->elements[current_position].scope_level == scope_level)
        {
            yyerror("variable %s is already declared at (%zu,%zu)", name, varlist->elements[current_position].decl_line, varlist->elements[current_position].decl_column);
            return;
        }

        const int error = VariableList_replace(varlist, name, strlen(name), type, scope_level, constant, initialized, data, yylloc->first_line, yylloc->first_column, current_position);
        if(error == -1)
        {
            yyerror("not enough memory to declare variable %s", name);
            abort();
        }
    }
    else
    {
        const int error = VariableList_insertAt(varlist, name, strlen(name), type, scope_level, constant, initialized, data, yylloc->first_line, yylloc->first_column, insert_position);
        if(error == -1)
        {
            yyerror("not enough memory to declare variable %s", name);
            abort();
        }
    }
}



void declareFunction(FunctionList* funclist, int scope_level, char* name, const Type* return_type, TypeList* typelist, const YYLTYPE* yylloc)
{
    if(name == NULL)
    {
        yyerror("not enough memory to declare function");
        abort();
    }

    int insert_position;
    const int current_position = FunctionList_find(funclist, name, typelist, &insert_position);

    if(current_position >= 0)
    {
        if(funclist->elements[current_position].scope_level == scope_level)
        {
            yyerror("function %s is already declared at (%zu,%zu)", name, funclist->elements[current_position].decl_line, funclist->elements[current_position].decl_column);
            return;
        }

        const int error = FunctionList_replace(funclist, name, strlen(name), scope_level, return_type, typelist, yylloc->first_line, yylloc->first_column, current_position);
        if(error == -1)
        {
            yyerror("not enough memory to declare function %s", name);
            abort();
        }
    }
    else
    {
        const int error = FunctionList_insertAt(funclist, name, strlen(name), scope_level, return_type, typelist, yylloc->first_line, yylloc->first_column, insert_position);
        if(error == -1)
        {
            yyerror("not enough memory to declare function %s", name);
            abort();
        }
    }
}



void enterBlock()
{
    if(VariableListStack_push(&varliststack, &varlist) != 0)
    {
        yyerror("not enough memory to push variable declarations list on the stack");
        abort();
    }

    if(FunctionListStack_push(&funcliststack, &funclist) != 0)
    {
        yyerror("not enough memory to push function declarations list on the stack");
        abort();
    }

    ++scope_level;
}
void exitBlock()
{
    VariableListStack_pop(&varliststack, &varlist);
    FunctionListStack_pop(&funcliststack, &funclist);
    --scope_level;
}



void checkIfVariableIsDeclared(const char* name)
{
    const int position = VariableList_find(&varlist, name, NULL);
    if(position == -1)
        yyerror("Variable %s is undeclared", name);
}
void checkIfVariableIsInitialized(const char* name)
{
    const int position = VariableList_find(&varlist, name, NULL);
    if(position >= 0 && varlist.elements[position].initialized == false)
        yywarning("Variable %s was not explicitly initialized", name);
}
