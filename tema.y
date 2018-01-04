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

int yylex();
int yywrap();

extern FILE* yyin;
extern FILE* yyout;
extern int error_count;
extern int warning_count;
int scope_level = 0;

VariableList varlist = {0};
VariableListStack varliststack = {0};

FunctionList funclist = {0};
FunctionListStack funcliststack = {0};

PrintQueue printqueue = {0};



Variable* declareVariable(VariableList* varlist, int scope_level, char* name, const Type* type, bool constant, bool initialized, const YYLTYPE* yylloc);
Function* declareFunction(FunctionList* funclist, int scope_level, char* name, const Type* return_type, TypeList* typelist, const YYLTYPE* yylloc);

void enterBlock();
void exitBlock();

Variable* isVarDecl(const char* name);
bool      isVarInit(const Variable* var);
void      initVar(Variable* var, const Expression* exp);

Function* isFuncDecl(const char* name, const TypeList* typelist);

bool isExpConvToBool(const Expression* exp);
void addExpToPrint(const Expression* exp);
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
    Variable* varval;
    Function* funcval;
    Expression expval;
}

/* Tokens */
%start Pgm
%token <intval> INT BOOL DOUBLE CHAR STRING VOID INVAL_TYPE
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
%type <expval> Exp

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
      | Exp ';'                       {Expression_clear(&$<expval>1);}
      | '{' {enterBlock();} Stmts '}' {exitBlock();}
      | '{''}'

      | PRINT '(' Exp ')' ';'         {addExpToPrint(&$<expval>3); Expression_clear(&$<expval>3);}
      | RETURN Exp ';'                {Expression_clear(&$<expval>2);}

      | IF '(' Exp ')' Stmt           %prec NOELSE {isExpConvToBool(&$<expval>3); Expression_clear(&$<expval>3);}
      | IF '(' Exp ')' Stmt ELSE Stmt              {isExpConvToBool(&$<expval>3); Expression_clear(&$<expval>3);}

      | WHILE '(' Exp ')' Stmt        {isExpConvToBool(&$<expval>3); Expression_clear(&$<expval>3);}
      | DO Stmt WHILE '(' Exp ')' ';' {isExpConvToBool(&$<expval>5); Expression_clear(&$<expval>5);}

      | FOR '(' ForInitExp ';' ForCondExp ';' ForNextExp ')' Stmt
      ;



ForInitExp :
           | Exp     {Expression_clear(&$<expval>1);}
           | DeclVar
           ;
ForCondExp :
           | Exp     {isExpConvToBool(&$<expval>1); Expression_clear(&$<expval>1);}
           ;
ForNextExp :
           | Exp     {Expression_clear(&$<expval>1);}
           ;



Exp  : VarAccess   {if(isVarInit($<varval>1) == true) Expression_set(&$<expval>$, NULL, $<varval>1, NULL); else Expression_reset(&$<expval>$);}
     | FuncCall    {if($<funcval>1 != NULL) Expression_set(&$<expval>$, &$<funcval>1->return_type, NULL, NULL); else Expression_reset(&$<expval>$);}

     | INT_CONSTANT    {Expression_set(&$<expval>$, &Type_int   , NULL, &$1);}
     | BOOL_CONSTANT   {Expression_set(&$<expval>$, &Type_bool  , NULL, &$1);}
     | DOUBLE_CONSTANT {Expression_set(&$<expval>$, &Type_double, NULL, &$1);}
     | CHAR_CONSTANT   {Expression_set(&$<expval>$, &Type_char  , NULL, &$1);}
     | STRING_LITERAL  {Expression_set(&$<expval>$, &Type_string, NULL, &$1);}

     | Exp '=' Exp        {Expression_assign(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}

     | Exp ADD_ASSIGN Exp {Expression_addassign(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp SUB_ASSIGN Exp {Expression_subassign(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp MUL_ASSIGN Exp {Expression_mulassign(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp DIV_ASSIGN Exp {Expression_divassign(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp MOD_ASSIGN Exp {Expression_modassign(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}

     | Exp '+' Exp            {Expression_add(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp '-' Exp            {Expression_sub(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp '*' Exp            {Expression_mul(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp '/' Exp            {Expression_div(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp '%' Exp            {Expression_mod(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | '-' Exp      %prec ',' {Expression_neg(&$<expval>2, &$<expval>$); Expression_clear(&$<expval>2);}

     | INC_OP Exp {Expression_preinc (&$<expval>2, &$<expval>$); Expression_clear(&$<expval>2);}
     | DEC_OP Exp {Expression_predec (&$<expval>2, &$<expval>$); Expression_clear(&$<expval>2);}
     | Exp DEC_OP {Expression_postinc(&$<expval>1, &$<expval>$); Expression_clear(&$<expval>1);}
     | Exp INC_OP {Expression_postdec(&$<expval>1, &$<expval>$); Expression_clear(&$<expval>1);}

     | '!' Exp        {Expression_not(&$<expval>2, &$<expval>$); Expression_clear(&$<expval>2);}
     | Exp AND_OP Exp {Expression_and(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp OR_OP  Exp {Expression_or (&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}

     | Exp EQ_OP Exp {Expression_eq (&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp NE_OP Exp {Expression_neq(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp LE_OP Exp {Expression_leq(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp GE_OP Exp {Expression_geq(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp  '<'  Exp {Expression_low(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}
     | Exp  '>'  Exp {Expression_gre(&$<expval>1, &$<expval>3, &$<expval>$); Expression_clear(&$<expval>1); Expression_clear(&$<expval>3);}

     | '(' Exp ')'   {$<expval>$ = $<expval>2;}
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


DeclVar       : TypePredef ID               {Type t = {$1, NULL}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, false, &@2);}
              | TypePredef ID ArrayDeclSize {Type t = {$1, NULL}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, false, &@2);}
              | TypePredef ID '=' Exp       {Type t = {$1, NULL}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, true , &@2); if(var != NULL) initVar(var, &$<expval>4); Expression_clear(&$<expval>4);}

              | ID ID               {Type t = {CLASS, $1}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, false, &@2);}
              | ID ID ArrayDeclSize {Type t = {CLASS, $1}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, false, &@2);}
              | ID ID '=' Exp       {Type t = {CLASS, $1}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, true , &@2); if(var != NULL) initVar(var, &$<expval>4); Expression_clear(&$<expval>4);}

              | CONST TypePredef ID '=' Exp {Type t = {$2, NULL}; Variable* var = declareVariable(&varlist, scope_level, $3, &t, true, true, &@3); if(var != NULL) initVar(var, &$<expval>5); Expression_clear(&$<expval>5);}
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

DeclParam             : TypePredef ID {$$.type = $1; $$.class_name = NULL; Type t = {$1, NULL}; declareVariable(&varlist, scope_level, $2, &t, false, true, &@2);}
                      | ID ID         {$$.type = CLASS; $$.class_name = $1; Type t = {CLASS, $1}; declareVariable(&varlist, scope_level, $2, &t, false, true, &@2);}
                      ;



/*********************/
/* Class declaration */
/*********************/

AccessModifier   : PUBLIC
                 | PRIVATE
                 ;

DeclClass        : CLASS ID {enterBlock(); Type t = {CLASS, strdup($2)}; declareVariable(&varlist, scope_level, strdup("this"), &t, true, true, &yylloc);} '{' DeclClassMembers '}' {exitBlock();}
                 ;

DeclClassMembers : DeclClassMember
                 | DeclClassMembers DeclClassMember
                 ;

DeclClassMember  : AccessModifier ClassDeclVar ';'
                 | AccessModifier DeclFunc
                 ;



ClassDeclVar     : TypePredef ID               {Type t = {$1, NULL}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, true, &@2);}
                 | TypePredef ID ArrayDeclSize {Type t = {$1, NULL}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, true, &@2);}

                 | ID ID               {Type t = {CLASS, $1}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, true, &@2);}
                 | ID ID ArrayDeclSize {Type t = {CLASS, $1}; Variable* var = declareVariable(&varlist, scope_level, $2, &t, false, true, &@2);}
                 ;



/*******************/
/* Variable access */
/*******************/

VarAccess       : ID                  {$<varval>$ = isVarDecl($<idval>1); free($<idval>1);}
                | ID VarAccessExtra   {$<varval>$ = NULL; isVarDecl($<idval>1); free($<idval>1);}
                | THIS                {$<varval>$ = isVarDecl($<idval>1); free($<idval>1);}
                | THIS VarAccessExtra {$<varval>$ = NULL; isVarDecl($<idval>1); free($<idval>1);}
                ;

VarAccessExtra  : '.' ID                       {free($2);}
                | '.' ID VarAccessExtra        {free($2);}
                | ArrayIndexing                {}
                | ArrayIndexing VarAccessExtra {}
                ;

ArrayIndexing   : '[' Exp ']'               {Expression_clear(&$<expval>2);}
                | '[' Exp ']' ArrayIndexing {Expression_clear(&$<expval>2);}
                ;



/*****************/
/* Function call */
/*****************/

FuncCall         : FuncAccess '(' FuncParamExpList ')' {Function* func = isFuncDecl($<idval>1, &$<typelistval>3); $<funcval>$ = func; TypeList_clear(&$<typelistval>3); free($<idval>1);}
                 ;

FuncParamExpList :                          {$<typelistval>$.elements = NULL; $<typelistval>$.capacity = 0; $<typelistval>$.size = 0;}
                 | Exp                      {$<typelistval>$.elements = NULL; $<typelistval>$.capacity = 0; $<typelistval>$.size = 0; TypeList_insert(&$<typelistval>$, &$<expval>1.type); Expression_clear(&$<expval>1);}
                 | FuncParamExpList ',' Exp {$<typelistval>$ = $<typelistval>1; TypeList_insert(&$<typelistval>$, &$<expval>3.type); Expression_clear(&$<expval>3);}
                 ;

FuncAccess       : ID                   {$<idval>$ = $<idval>1;}
                 | ID FuncAccessExtra   {$<idval>$ = NULL; isVarDecl($<idval>1); free($<idval>1);}
                 | THIS                 {$<idval>$ = $<idval>1;}
                 | THIS FuncAccessExtra {$<idval>$ = NULL; isVarDecl($<idval>1); free($<idval>1);}
                 ;

FuncAccessExtra  : '.' ID                        {free($2);}
                 | '.' ID FuncAccessExtra        {free($2);}
                 | ArrayIndexing FuncAccessExtra {}
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
int yywrap()
{
    if(error_count == 0)
    {
        for(int i = 0; i < printqueue.size; ++i)
            fprintf(yyout, "%ld\n", printqueue.elements[i]);
        PrintQueue_clear(&printqueue);
    }

    return 1;
}

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



Variable* declareVariable(VariableList* varlist, int scope_level, char* name, const Type* type, bool constant, bool initialized, const YYLTYPE* yylloc)
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
            yyerror("variable %s was already declared at (%zu,%zu)", name, varlist->elements[current_position].decl_line, varlist->elements[current_position].decl_column);
            return NULL;
        }

        const int error = VariableList_replace(varlist, name, strlen(name), type, scope_level, constant, initialized, yylloc->first_line, yylloc->first_column, current_position);
        if(error == -1)
        {
            yyerror("not enough memory to declare variable %s", name);
            abort();
        }
    }
    else
    {
        const int error = VariableList_insertAt(varlist, name, strlen(name), type, scope_level, constant, initialized, yylloc->first_line, yylloc->first_column, insert_position);
        if(error == -1)
        {
            yyerror("not enough memory to declare variable %s", name);
            abort();
        }
    }

    return &varlist->elements[insert_position];
}

Function* declareFunction(FunctionList* funclist, int scope_level, char* name, const Type* return_type, TypeList* typelist, const YYLTYPE* yylloc)
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
            yyerror("function %s was already declared at (%zu,%zu) with the following parameter types",
                name, funclist->elements[current_position].decl_line, funclist->elements[current_position].decl_column);
            fputc('\t', stderr);
            TypeList_print(typelist, stderr);
            fputc('\n', stderr);
            return NULL;
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

    return &funclist->elements[insert_position];
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



Variable* isVarDecl(const char* name)
{
    if(name == NULL)
        return NULL;

    const int position = VariableList_find(&varlist, name, NULL);
    if(position == -1)
    {
        yyerror("Variable %s is undeclared", name);
        return NULL;
    }

    return &varlist.elements[position];
}
bool isVarInit(const Variable* var)
{
    if(var == NULL)
        return false;

    if(var->initialized == false)
        yyerror("Variable %s was not explicitly initialized", var->name);
    return var->initialized;
}
void initVar(Variable* var, const Expression* exp)
{
    if(exp->type.type == INVAL_TYPE)
        return;
    if(Type_equal(&var->type, &exp->type) == false)
    {
        yyerror("the sides of '=' have different types");
        return;
    }

    switch(var->type.type)
    {
    case INT:    var->intval    = exp->intval;    break;
    case BOOL:   var->boolval   = exp->boolval;   break;
    case DOUBLE: var->doubleval = exp->doubleval; break;
    case CHAR:   var->charval   = exp->charval;   break;
    case STRING: var->strval    = exp->strval;    break;
    case CLASS:  break;
    }
}

Function* isFuncDecl(const char* name, const TypeList* typelist)
{
    if(name == NULL || typelist == NULL)
        return NULL;

    const int position = FunctionList_find(&funclist, name, typelist, NULL);
    if(position == -1)
    {
        yyerror("No function %s was declared with the following parameter types", name);
        fputc('\t', stderr);
        TypeList_print(typelist, stderr);
        fputc('\n', stderr);
        return NULL;
    }

    return &funclist.elements[position];
}

bool isExpConvToBool(const Expression* exp)
{
    switch(exp->type.type)
    {
    case INT:
    case BOOL:
    case DOUBLE:
    case CHAR:
    case STRING:
        return true;
    }

    return false;
}
void addExpToPrint(const Expression* exp)
{
    if(exp->type.type == INVAL_TYPE)
        return;

    if(exp->type.type != INT)
    {
        yyerror("Invalid parameter of type %s. Function print has the following signature: void print(int)", Type_toString(&exp->type));
        return;
    }

    if(PrintQueue_push(&printqueue, exp->intval) != 0)
    {
        yyerror("not enough memory to add integer to the print queue");
        abort();
    }
}
