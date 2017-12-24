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
    /* Types and ids */
"int"                  {return TypeInt;}
"float"                {return TypeFloat;}
"char"                 {return TypeChar;}
"string"               {return TypeString;}
[_a-zA-Z][_a-zA-Z0-9]* {return Id;}

    /* Constants */
(0|[1-9][0-9]*)       {return Int;}
([0-9]?\.[0-9]+)(f|F) {return Float;}
\'(.)\'               {return Char;}
\"([^"\n]|\\\")*\"    {return String;}



    /* Comments */
"//".*                 {}
"/**/"                 {}
"/*"([^*\n]|\*[^/\n])* {skipMultilineComment();}

    /* New line. Force lex to update yylineno and update yycolumnno manually */
[ \t\v\r]*\n  {yycolumnno = 1;}

    /* Any whitespace except new line */
[ \t\v]+      {}

    /* Anything else that does not contain whitespaces */
[^ \t\v\r\n]+ {yyerror("unknown token");}



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
