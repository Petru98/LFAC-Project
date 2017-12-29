#include "util.h"
#include "y.tab.h"

void* memdup(const void* mem, size_t size)
{
   void* new_mem = malloc(size);
   if(new_mem != NULL)
       memcpy(new_mem, mem, size);

   return new_mem;
}

int strassign(char** dst, int* dst_capacity, const char* src)
{
    const int len = strlen(src);
    if((len + 1) > (*dst_capacity))
    {
        char* new_dst = malloc(len + 1);
        if(new_dst == NULL)
            return -1;

        free(*dst);
        (*dst) = new_dst;
        (*dst_capacity) = len + 1;
    }

    memcpy(*dst, src, len);
    return len;
}



/* Type */
void Type_arrayDestroy(Type* array, int size)
{
    for(int i = 0; i < size; ++i)
        if(array[i].type == CLASS)
            free(array[i].class_name);
    free(array);
}

int Type_arrayInsert(Type** array, int* size, int* capacity, Type* element)
{
    if(size == capacity)
    {
        const int new_capacity = (*capacity) + 1;

        Type* new_array = realloc(*array, new_capacity);
        if(new_array == NULL)
            return -1;

        (*array) = new_array;
        (*capacity) = new_capacity;
    }

    (*array)[*size] = (*element);
    ++(*size);
}



/* VariableList */
void VariableList_destroy(VariableList* list)
{
    for(int i = 0; i < list->size; ++i)
    {
        switch(list->elements[i]->type)
        {
        case STRING:
            free(list->elements[i]->strval);
            break;
        case CLASS:
            free(list->elements[i]->class_name);
            break;
        }

        free(list->elements[i]);
    }

    free(list->elements);

    list->size = 0;
    list->capacity = 0;
    list->elements = NULL;
}

int VariableList_find(VariableList* list, const char* name, int* insert_pos)
{
    int first = 0;
    int last = list->size - 1;

    while(first <= last)
    {
        const int mid = (first + last) / 2;
        const int cmp = strcmp(name, list->elements[mid]->name);

        if(cmp == 0)
            return mid;

        if(cmp < 0)
            last = mid - 1;
        else
            first = mid + 1;
    }

    if(insert_pos != NULL)
        (*insert_pos) = first;
    return -1;
}

int VariableList_insertElement(VariableList* list, Variable* element, int position)
{
    if(list->size == list->capacity)
    {
        int new_capacity = 1 + list->capacity * sizeof(Variable*) * 2;
        Variable** new_list = realloc(list->elements, new_capacity);
        if(new_list == NULL)
        {
            new_capacity = 1 + list->capacity * sizeof(Variable*);
            new_list = realloc(list->elements, new_capacity);
            if(new_list == NULL)
                return -1;
        }

        list->elements = new_list;
        list->capacity = new_capacity;
    }

    memmove(list->elements + position + 1, list->elements + position, (list->size - position) * sizeof(Variable*));
    list->elements[position] = element;
    ++list->size;

    return 0;
}

int VariableList_insertAt(VariableList* list, const char* name, int name_length, int type, int scope_level, bool constant, void* data, int position)
{
    Variable* element = malloc(sizeof(Variable) + name_length + 1);
    if(element == NULL)
        return -1;

    void* free_on_error = NULL;

    switch(type)
    {
    case INT:    element->intval    = *(const int*)   data; break;
    case BOOL:   element->boolval   = *(const bool*)  data; break;
    case DOUBLE: element->doubleval = *(const double*)data; break;
    case CHAR:   element->charval   = *(const char*)  data; break;
    case STRING:
    {
        if((*((char**)data)) == NULL)
            element->strval = NULL;
        else
        {
            element->strval = memdup((*((char**)data)), strlen((*((char**)data))) + 1);
            if(element->strval == NULL)
                return -1;

            free_on_error = element->strval;
        }
        break;
    }
    case CLASS:
    {
        if((*((char**)data)) == NULL)
            return -1;

        element->class_name = memdup((*((char**)data)), strlen((*((char**)data))) + 1);
        if(element->class_name == NULL)
            return -1;

        free_on_error = element->class_name;
        break;
    }
    }

    memcpy(element->name, name, name_length + 1);
    element->name_length = name_length;
    element->type        = type;
    element->scope_level = scope_level;
    element->constant    = constant;

    if(VariableList_insertElement(list, element, position) != 0)
    {
        free(free_on_error);
        free(element);
        return -1;
    }

    return 0;
}

int VariableList_insert(VariableList* list, const char* name, int name_length, int type, int scope_level, bool constant, void* data)
{
    int position;
    if(yylloc.first_line == 53)
    {
        int x = 0;
    }
    if(VariableList_find(list, name, &position) != -1)
        return 1;

    return VariableList_insertAt(list, name, name_length, type, scope_level, constant, data, position);
}



/* FunctionList */
void FunctionList_destroy(FunctionList* list)
{
    for(int i = 0; i < list->size; ++i)
    {
        if(list->elements[i]->return_type.type == CLASS)
            free(list->elements[i]->return_type.class_name);

        for(int j = 0; j < list->elements[i]->params_count; ++i)
            if(list->elements[i]->params[j].type == CLASS)
                free(list->elements[i]->params[j].class_name);

        free(list->elements[i]);
    }

    free(list->elements);

    list->size = 0;
    list->capacity = 0;
    list->elements = NULL;
}

int FunctionList_find(FunctionList* list, const char* name, int* insert_pos)
{
    int first = 0;
    int last = list->size - 1;

    while(first <= last)
    {
        const int mid = (first + last) / 2;
        const int cmp = strcmp(name, list->elements[mid]->name);

        if(cmp == 0)
            return mid;

        if(cmp < 0)
            last = mid - 1;
        else
            first = mid + 1;
    }

    if(insert_pos != NULL)
        (*insert_pos) = first;
    return -1;
}

int FunctionList_insertElement(FunctionList* list, Function* element, int position)
{
    if(list->size == list->capacity)
    {
        int new_capacity = 1 + list->capacity * sizeof(Function*) * 2;
        Function** new_list = realloc(list->elements, new_capacity);
        if(new_list == NULL)
        {
            new_capacity = 1 + list->capacity * sizeof(Function*);
            new_list = realloc(list->elements, new_capacity);
            if(new_list == NULL)
                return -1;
        }

        list->elements = new_list;
        list->capacity = new_capacity;
    }

    memmove(list->elements + position + 1, list->elements + position, (list->size - position) * sizeof(Function*));
    list->elements[position] = element;
    ++list->size;

    return 0;
}

int FunctionList_insertAt(FunctionList* itemlist, const char* name, int name_length, int scope_level, const Type* return_type, Type* params, int params_count, int position)
{
    Function* element = malloc(sizeof(Function) + name_length + 1);
    if(element == NULL)
        return -1;

    if(FunctionList_insertElement(itemlist, element, position) == -1)
    {
        free(element);
        return -1;
    }

    memcpy(element->name, name, name_length + 1);
    element->name_length  = name_length;
    element->scope_level  = scope_level;
    element->return_type  = (*return_type);
    element->params       = params;
    element->params_count = params_count;

    return 0;
}

int FunctionList_insert(FunctionList* list, const char* name, int name_length, int scope_level, const Type* return_type, Type* params, int params_count)
{
    int position;
    if(FunctionList_find(list, name, &position) != -1)
        return 1;

    return FunctionList_insertAt(list, name, name_length, scope_level, return_type, params, params_count, position);
}
