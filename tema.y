%{
#include <stdio.h>

extern int yylineno;
void yyerror(const char* msg);
int yylex();

%}

%start ProgramStart

%%
ProgramStart : ;

%%
void yyerror(const char* msg)
{
    fprintf(stderr, "error: line %d: %s\n", yylineno, msg);
}

int main(int argc, char** argv)
{
    yyparse();
    return 0;
}
