#ifndef INCLUDED_YYLLOC_H
#define INCLUDED_YYLLOC_H

#include <stdlib.h>

#define YYLTYPE yyltype
typedef struct yyltype
{
    size_t first_line;
    size_t first_column;
    size_t last_line;
    size_t last_column;
} yyltype;

#endif
