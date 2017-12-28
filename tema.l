/******************************************************************************/
/******************************** Declarations ********************************/
/******************************************************************************/

/* C code */
%{
#include "y.tab.h"

void yyerror(const char* msg);
void yywarning(const char* msg);

void skipMultilineComment();

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
"int"       {return INT;}
"bool"      {return BOOL;}
"double"    {return DOUBLE;}
"float"     {return FLOAT;}
"char"      {return CHAR;}
"string"    {return STRING;}
"void"      {return VOID;}
"const"     {return CONST;}
"if"        {return IF;}
"else"      {return ELSE;}
"while"     {return WHILE;}
"do"        {return DO;}
"for"       {return FOR;}
"return"    {return RETURN;}
"class"     {return CLASS;}
"this"      {return THIS;}
"public"    {return PUBLIC;}
"private"   {return PRIVATE;}



    /* Constants */
(0|[-+]?[1-9][0-9]*)  {return INT_CONSTANT;}
(0|[1-9][0-9]*)(u|U)  {return UINT_CONSTANT;}
("false"|"true")      {return BOOL_CONSTANT;}
([0-9]?\.[0-9]+)      {return DOUBLE_CONSTANT;}
([0-9]?\.[0-9]+)(f|F) {return FLOAT_CONSTANT;}
\'(.)\'               {return CHAR_CONSTANT;}
\"([^"\n]|\\\")*\"    {return STRING_LITERAL;}



    /* Id */
[_a-zA-Z][_a-zA-Z0-9]* {return ID;}



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
void yyerror(const char* msg)
{
    fprintf(stderr, "error: (%zu, %zu)->(%zu, %zu): %s\n", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column, msg);
}
void yywarning(const char* msg)
{
    fprintf(stderr, "warning: (%zu, %zu)->(%zu, %zu): %s\n", yylloc.first_line, yylloc.first_column, yylloc.last_line, yylloc.last_column, msg);
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
