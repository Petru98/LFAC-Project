#include "util.h"
#include "y.tab.h"

extern int scope_level;



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
void TypeList_destroy(TypeList* list)
{
    for(int i = 0; i < list->size; ++i)
        if(list->elements[i].type == CLASS)
            free(list->elements[i].class_name);

    free(list->elements);
    list->elements = NULL;
    list->capacity = 0;
    list->size = 0;
}

int TypeList_insert(TypeList* list, Type* element)
{
    if(list->size == list->capacity)
    {
        int new_capacity = 1 + list->capacity * 2;
        Type* new_list = realloc(list->elements, new_capacity * sizeof(list->elements[0]));
        if(new_list == NULL)
        {
            int new_capacity = 1 + list->capacity;
            new_list = realloc(list->elements, new_capacity * sizeof(list->elements[0]));
            if(new_list == NULL)
                return -1;
        }

        list->elements = new_list;
        list->capacity = new_capacity;
    }

    list->elements[list->size] = (*element);
    ++list->size;
}



/* VariableList */
void VariableList_destroy(VariableList* list, int scope_level)
{
    for(int i = 0; i < list->size; ++i)
    {
        if(list->elements[i].scope_level == scope_level || scope_level == -1)
        {
            switch(list->elements[i].type)
            {
            case STRING:
                free(list->elements[i].strval);
                break;
            case CLASS:
                free(list->elements[i].class_name);
                break;
            }

            free(list->elements[i].name);
        }
    }

    free(list->elements);
    list->elements = NULL;
    list->capacity = 0;
    list->size = 0;
}

int VariableList_copy(const VariableList* src, VariableList* dst)
{
    dst->elements = memdup(src->elements, src->capacity * sizeof(src->elements[0]));
    if(dst->elements == NULL)
        return -1;

    dst->capacity = src->capacity;
    dst->size = src->size;
    return 0;
}

int VariableList_find(VariableList* list, const char* name, int* insert_pos)
{
    int first = 0;
    int last = list->size - 1;

    while(first <= last)
    {
        const int mid = (first + last) / 2;
        const int cmp = strcmp(name, list->elements[mid].name);

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
        int new_capacity = 1 + list->capacity * 2;
        Variable* new_list = realloc(list->elements, new_capacity * sizeof(list->elements[0]));
        if(new_list == NULL)
        {
            new_capacity = 1 + list->capacity;
            new_list = realloc(list->elements, new_capacity * sizeof(list->elements[0]));
            if(new_list == NULL)
                return -1;
        }

        list->elements = new_list;
        list->capacity = new_capacity;
    }

    memmove(list->elements + position + 1, list->elements + position, (list->size - position) * sizeof(list->elements[0]));
    list->elements[position] = (*element);
    ++list->size;

    return 0;
}

int VariableList_insertAt(VariableList* list, char* name, int name_length, int type, int scope_level, bool constant, void* data, int decl_line, int decl_column, int position)
{
    Variable element;

    switch(type)
    {
    case INT:    element.intval    = *(int*)   data; break;
    case BOOL:   element.boolval   = *(bool*)  data; break;
    case DOUBLE: element.doubleval = *(double*)data; break;
    case CHAR:   element.charval   = *(char*)  data; break;
    case STRING:
    {
        element.strval = (*((char**)data));
        break;
    }
    case CLASS:
    {
        element.class_name = (*((char**)data));
        break;
    }
    }

    element.name        = name;
    element.name_length = name_length;
    element.type        = type;
    element.scope_level = scope_level;
    element.constant    = constant;
    element.decl_line   = decl_line;
    element.decl_column = decl_column;

    if(VariableList_insertElement(list, &element, position) != 0)
        return -1;

    return 0;
}

int VariableList_insert(VariableList* list, char* name, int name_length, int type, int scope_level, bool constant, void* data, int decl_line, int decl_column)
{
    int insert_position;
    if(VariableList_find(list, name, &insert_position) != -1)
        return 1;

    return VariableList_insertAt(list, name, name_length, type, scope_level, constant, data, decl_line, decl_column, insert_position);
}

int VariableList_replace(VariableList* list, char* name, int name_length, int type, int scope_level, bool constant, void* data, int decl_line, int decl_column, int position)
{
    Variable* element = &list->elements[position];

    switch(type)
    {
    case INT:    element->intval    = *(int*)   data; break;
    case BOOL:   element->boolval   = *(bool*)  data; break;
    case DOUBLE: element->doubleval = *(double*)data; break;
    case CHAR:   element->charval   = *(char*)  data; break;
    case STRING:
    {
        element->strval = (*((char**)data));
        break;
    }
    case CLASS:
    {
        element->class_name = (*((char**)data));
        break;
    }
    }

    element->name        = name;
    element->name_length = name_length;
    element->type        = type;
    element->scope_level = scope_level;
    element->constant    = constant;
    element->decl_line   = decl_line;
    element->decl_column = decl_column;

    return 0;
}



void VariableListStack_destroy(VariableListStack* stack)
{
    for(int i = 0; i < stack->size; ++i)
        VariableList_destroy(&stack->elements[i], i);

    free(stack->elements);
    stack->elements = NULL;
    stack->capacity = 0;
    stack->size = 0;
}

int VariableListStack_push(VariableListStack* stack, const VariableList* list)
{
    if(stack->size == stack->capacity)
    {
        int new_capacity = 1 + stack->capacity * 2;
        VariableList* new_stack = realloc(stack->elements, new_capacity * sizeof(stack->elements[0]));
        if(new_stack == NULL)
        {
            int new_capacity = 1 + stack->capacity;
            VariableList* new_stack = realloc(stack->elements, new_capacity * sizeof(stack->elements[0]));
            if(new_stack == NULL)
                return -1;
        }

        stack->elements = new_stack;
        stack->capacity = new_capacity;
    }

    VariableList_copy(list, &stack->elements[stack->size]);
    ++stack->size;
    return 0;
}

int VariableListStack_pop(VariableListStack* stack, VariableList* list)
{
    if(stack->size == 0)
        return -1;

    --stack->size;
    VariableList_destroy(list, scope_level);
    VariableList_copy(&stack->elements[stack->size], list);
    return 0;
}

VariableList* VariableListStack_top(VariableListStack* stack)
{
    if(stack->size == 0)
        return NULL;
    return &stack->elements[stack->size - 1];
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
