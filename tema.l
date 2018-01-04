/******************************************************************************/
/******************************** Declarations ********************************/
/******************************************************************************/

/* C code */
%{
#include <errno.h>
#include <limits.h>
#include <math.h>
#include <stdarg.h>
#include "yylloc.h"
#include "util.h"
#include "y.tab.h"

void skipMultilineComment();

int error_count = 0;
int warning_count = 0;
size_t yycolumnno = 1;
extern YYLTYPE yylloc;

#define YY_USER_INIT         \
{                            \
    yylloc.first_line   = 1; \
    yylloc.first_column = 1; \
    yylloc.last_line    = 1; \
    yylloc.last_column  = 1; \
}

#define YY_USER_ACTION                             \
{                                                  \
    yylloc.first_line   = yylineno;                \
    yylloc.last_line    = yylineno;                \
    yylloc.first_column = yycolumnno;              \
    yylloc.last_column  = yycolumnno + yyleng - 0; \
    yycolumnno += yyleng;                          \
}
%}

/* Flags for lex */
%option yylineno



/******************************************************************************/
/*********************************** Rules ************************************/
/******************************************************************************/
%%
    /* Comments */
"//".*                 {}
"/**/"                 {}
"/*"([^*\n]|\*[^/\n])* {skipMultilineComment();}



    /* Keywords */
"int"       {yylval.intval = INT; return INT;}
"bool"      {yylval.intval = BOOL; return BOOL;}
"double"    {yylval.intval = DOUBLE; return DOUBLE;}
"char"      {yylval.intval = CHAR; return CHAR;}
"string"    {yylval.intval = STRING; return STRING;}
"void"      {yylval.intval = VOID; return VOID;}
"const"     {return CONST;}
"print"     {return PRINT;}
"if"        {return IF;}
"else"      {return ELSE;}
"while"     {return WHILE;}
"do"        {return DO;}
"for"       {return FOR;}
"return"    {return RETURN;}
"class"     {return CLASS;}
"this"      {yylval.idval = strdup("this"); if(yylval.idval == NULL) {yyerror("not enough memory"); abort();} return THIS;}
"public"    {return PUBLIC;}
"private"   {return PRIVATE;}



    /* Constants */
(0|[-+]?[1-9][0-9]*) {
    yylval.intval = strtol(yytext, NULL, 10);
    if((yylval.intval == LONG_MAX || yylval.intval == LONG_MIN) && errno == ERANGE)
        yyerror("integer constant is out of the range of representable values");
    return INT_CONSTANT;
}

("false"|"true") {
    yylval.boolval = ((*yytext) == 't');
    return BOOL_CONSTANT;
}

([0-9]?\.[0-9]+) {
    yylval.doubleval = strtod(yytext, NULL);
    if((yylval.doubleval == HUGE_VAL || yylval.doubleval == -HUGE_VAL) && errno == ERANGE)
        yyerror("double constant is out of the range of representable values");
    return DOUBLE_CONSTANT;
}

\'(.)\' {
    yylval.charval = yytext[1];
    return CHAR_CONSTANT;
}

\"([^"\n]|\\\")*\" {
    yylval.strval = malloc(yyleng - 2 + 1);
    if(yylval.strval == NULL)
        yyerror("not enough memory for strval");
    else
        strncpy(yylval.strval, yytext + 1, yyleng - 2);
    return STRING_LITERAL;
}



    /* Id */
[_a-zA-Z][_a-zA-Z0-9]* {
    yylval.idval = strdup(yytext);
    if(yylval.idval == NULL)
        yyerror("not enough memory for idval");
    return ID;
}



    /* Operators and punctuation */
"+=" {return ADD_ASSIGN;}
"-=" {return SUB_ASSIGN;}
"*=" {return MUL_ASSIGN;}
"/=" {return DIV_ASSIGN;}
"%=" {return MOD_ASSIGN;}
"++" {return INC_OP;}
"--" {return DEC_OP;}
"&&" {return AND_OP;}
"||" {return OR_OP;}
"==" {return EQ_OP;}
"!=" {return NE_OP;}
"<=" {return LE_OP;}
">=" {return GE_OP;}
";"  {return ';';}
","  {return ',';}
":"  {return ':';}
"{"  {return '{';}
"}"  {return '}';}
"("  {return '(';}
")"  {return ')';}
"["  {return '[';}
"]"  {return ']';}
"<"  {return '<';}
">"  {return '>';}
"="  {return '=';}
"+"  {return '+';}
"-"  {return '-';}
"*"  {return '*';}
"/"  {return '/';}
"%"  {return '%';}
"!"  {return '!';}
"."  {return '.';}
"?"  {return '?';}



    /* New line. Force lex to update yylineno and update yycolumnno manually */
[ \t\v\r]*\n  {yycolumnno = 1;}

    /* Any whitespace except new line */
[ \t\v]+      {}

    /* Anything else. Let yacc decide if the token is actually 2 valid tokens concatenated */
    /* This is for situations where tokens are not separated by whitespace like: variable_name; */
.             {return (*yytext);}



%%
/******************************************************************************/
/*********************************** C code ***********************************/
/******************************************************************************/
void yyerror(const char* msg, ...)
{
    va_list args;
    va_start(args, msg);
    fprintf(stderr, "error: (%zu, %zu)->(%zu, %zu): ", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column);
    vfprintf(stderr, msg, args);
    fputc('\n', stderr);
    va_end(args);

    ++error_count;
}
void yywarning(const char* msg, ...)
{
    va_list args;
    va_start(args, msg);
    fprintf(stderr, "warning: (%zu, %zu)->(%zu, %zu): ", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column);
    vfprintf(stderr, msg, args);
    fputc('\n', stderr);
    va_end(args);

    ++warning_count;
}

void skipMultilineComment()
{
    char prev_char = 0;

    while(1)
    {
        char c = input();

        if(c == 0)
        {
            yywarning("multiline comment not closed");
            break;
        }
        else if(c == '\n')
        {
            ++yylloc.last_line;
            yylloc.last_column = 1;
        }
        else
        {
            ++yylloc.last_column;
            if(prev_char == '*' && c == '/')
                break;
        }

        prev_char = c;
    }

    yylineno = yylloc.last_line;
    yycolumnno = yylloc.last_column;
}
