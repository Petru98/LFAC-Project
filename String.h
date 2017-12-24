#ifndef INCLUDED_STRING_H
#define INCLUDED_STRING_H

#include <string.h>
#include <stdlib.h>

typedef struct String
{
    int length;
    char str[];
} String;

typedef struct StringList
{
    String** strings;
    int size;
    int capacity;
} StringList;



static inline void StringList_destroy(StringList* strlist)
{
    for(int i = 0; i < strlist->size; ++i)
        free(strlist->strings[i]);
    free(strlist->strings);

    strlist->size = 0;
    strlist->capacity = 0;
    strlist->strings = NULL;
}

static inline int StringList_find(StringList* strlist, const char* str, int* insert_pos)
{
    int first = 0;
    int last = strlist->size - 1;

    while(first <= last)
    {
        const int mid = (first + last) / 2;
        const int cmp = strcmp(str, strlist->strings[mid]->str);

        if(cmp == 0)
            return mid;

        if(cmp == -1)
            last = mid - 1;
        else
            first = mid + 1;
    }

    if(insert_pos != NULL)
        (*insert_pos) = first;
    return -1;
}

static inline int StringList_insertElement(StringList* strlist, String* elem, int position)
{
    if(strlist->size == strlist->capacity)
    {
        String** new_list = realloc(strlist->strings, (strlist->capacity * sizeof(String*)) * 2);
        if(new_list == NULL)
            return -1;
        strlist->strings = new_list;
    }

    for(int i = strlist->size; i > position; --i)
        strlist->strings[i] = strlist->strings[i - 1];
    strlist->strings[position] = elem;

    return 1;
}

static inline int StringList_addStringAt(StringList* strlist, const char* str, int length, int position)
{
    String* element = malloc(sizeof(String) + length + 1);
    if(element == NULL)
        return -1;

    if(StringList_insertElement(strlist, element, position) == -1)
    {
        free(element);
        return -1;
    }

    strcpy(element->str, str);
    element->length = length;
    return 1;
}

static inline int StringList_addString(StringList* strlist, const char* str, int length)
{
    int position;
    if(StringList_find(strlist, str, &position) != -1)
        return 0;

    return StringList_addStringAt(strlist, str, length, position);
}

#endif
