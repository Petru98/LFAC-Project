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

int compareStrings(const char* lval, const char* rval)
{
    if(lval == NULL || lval[0] == '\0')
    {
        if(rval == NULL || rval[0] == '\0')
            return 0;
        return -1;
    }

    if(rval == NULL || rval[0] == '\0')
        return 1;
    return strcmp(lval, rval);
}
char* concatStrings(const char* lval, const char* rval)
{
    const int llen = strlen(lval);
    const int rlen = strlen(rval);
    char* result = malloc(llen + rlen + 1);
    if(result == NULL)
    {
        yyerror("not enough memory to allocate %d bytes for string", llen + rlen + 1);
        abort();
    }

    memcpy(result, lval, llen);
    memcpy(result + llen, rval, rlen + 1);
    return result;
}
char* appendString(char* lval, const char* rval)
{
    const int llen = strlen(lval);
    const int rlen = strlen(rval);
    char* result = malloc(llen + rlen + 1);
    if(result == NULL)
    {
        yyerror("not enough memory to allocate %d bytes for string", llen + rlen + 1);
        abort();
    }

    memcpy(result, lval, llen);
    memcpy(result + llen, rval, rlen + 1);
    free(lval);
    return result;
}



/* Type */
const Type Type_invalid = {INVAL_TYPE, NULL};
const Type Type_int     = {INT, NULL};
const Type Type_bool    = {BOOL, NULL};
const Type Type_double  = {DOUBLE, NULL};
const Type Type_char    = {CHAR, NULL};
const Type Type_string  = {STRING, NULL};
const Type Type_void    = {VOID, NULL};

bool Type_equal(const Type* lval, const Type* rval)
{
    return lval->type == rval->type && (lval->type != CLASS || strcmp(lval->class_name, rval->class_name) == 0);
}



void TypeList_clear(TypeList* list)
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

bool TypeList_equal(const TypeList* llist, const TypeList* rlist)
{
    if(llist->size != rlist->size)
        return false;

    for(int i = 0; i < llist->size; ++i)
    {
        if(llist->elements[i].type != rlist->elements[i].type)
            return false;
        if(llist->elements[i].type == CLASS && strcmp(llist->elements[i].class_name, rlist->elements[i].class_name) != 0)
            return false;
    }

    return true;
}



/* VariableList */
void VariableList_clear(VariableList* list, int scope_level)
{
    for(int i = 0; i < list->size; ++i)
    {
        if(list->elements[i].scope_level == scope_level || scope_level == -1)
        {
            switch(list->elements[i].type.type)
            {
            case STRING:
                free(list->elements[i].strval);
                break;
            case CLASS:
                free(list->elements[i].type.class_name);
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

int VariableList_find(const VariableList* list, const char* name, int* insert_pos)
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

int VariableList_insertAt(VariableList* list, char* name, int name_length, const Type* type, int scope_level, bool constant, bool initialized,
                          int decl_line, int decl_column, int position)
{
    Variable element;

    switch(type->type)
    {
    case INT:    element.intval = 0;    break;
    case BOOL:   element.boolval = 0;   break;
    case DOUBLE: element.doubleval = 0; break;
    case CHAR:   element.charval = 0;   break;
    case STRING: element.strval = NULL; break;
    case CLASS:  break;
    }

    element.name        = name;
    element.name_length = name_length;
    element.type        = (*type);
    element.scope_level = scope_level;
    element.constant    = constant;
    element.initialized = initialized;
    element.decl_line   = decl_line;
    element.decl_column = decl_column;

    if(VariableList_insertElement(list, &element, position) != 0)
        return -1;

    return 0;
}

int VariableList_insert(VariableList* list, char* name, int name_length, const Type* type, int scope_level, bool constant, bool initialized,
                        int decl_line, int decl_column)
{
    int insert_position;
    if(VariableList_find(list, name, &insert_position) != -1)
        return 1;

    return VariableList_insertAt(list, name, name_length, type, scope_level, constant, initialized, decl_line, decl_column, insert_position);
}

int VariableList_replace(VariableList* list, char* name, int name_length, const Type* type, int scope_level, bool constant, bool initialized,
                         int decl_line, int decl_column, int position)
{
    Variable* element = &list->elements[position];

    switch(type->type)
    {
    case INT:    element->intval = 0;    break;
    case BOOL:   element->boolval = 0;   break;
    case DOUBLE: element->doubleval = 0; break;
    case CHAR:   element->charval = 0;   break;
    case STRING: element->strval = NULL; break;
    case CLASS:  break;
    }

    element->name        = name;
    element->name_length = name_length;
    element->type        = (*type);
    element->scope_level = scope_level;
    element->constant    = constant;
    element->initialized = initialized;
    element->decl_line   = decl_line;
    element->decl_column = decl_column;

    return 0;
}



/* VariableListStack */
void VariableListStack_clear(VariableListStack* stack)
{
    for(int i = 0; i < stack->size; ++i)
        VariableList_clear(&stack->elements[i], i);

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
            new_stack = realloc(stack->elements, new_capacity * sizeof(stack->elements[0]));
            if(new_stack == NULL)
                return -1;
        }

        stack->elements = new_stack;
        stack->capacity = new_capacity;
    }

    if(VariableList_copy(list, &stack->elements[stack->size]) != 0)
        return -1;

    ++stack->size;
    return 0;
}

int VariableListStack_pop(VariableListStack* stack, VariableList* list)
{
    if(stack->size == 0)
        return -1;

    --stack->size;
    VariableList_clear(list, scope_level);
    (*list) = stack->elements[stack->size];
    return 0;
}

VariableList* VariableListStack_top(VariableListStack* stack)
{
    if(stack->size == 0)
        return NULL;
    return &stack->elements[stack->size - 1];
}



/* FunctionList */
void FunctionList_clear(FunctionList* list, int scope_level)
{
    for(int i = 0; i < list->size; ++i)
    {
        if(list->elements[i].scope_level == scope_level || scope_level == -1)
        {
            if(list->elements[i].return_type.type == CLASS)
                free(list->elements[i].return_type.class_name);

            TypeList_clear(&list->elements[i].paramtypes);
            free(list->elements[i].name);
        }
    }

    free(list->elements);
    list->elements = NULL;
    list->capacity = 0;
    list->size = 0;
}

int FunctionList_copy(const FunctionList* src, FunctionList* dst)
{
    dst->elements = memdup(src->elements, src->capacity * sizeof(src->elements[0]));
    if(dst->elements == NULL)
        return -1;

    dst->capacity = src->capacity;
    dst->size = src->size;
    return 0;
}

int FunctionList_find(const FunctionList* list, const char* name, const TypeList* typelist, int* insert_pos)
{
    int first = 0;
    int last = list->size - 1;

    while(first <= last)
    {
        const int mid = (first + last) / 2;
        const int cmp = strcmp(name, list->elements[mid].name);

        if(cmp == 0)
        {
            int tmp;
            if(insert_pos == NULL)
                insert_pos = &tmp;

            int found_pos = -1;
            (*insert_pos) = mid;

            while((*insert_pos) < list->size && strcmp(name, list->elements[*insert_pos].name) == 0)
            {
                if(found_pos == -1 && TypeList_equal(&list->elements[*insert_pos].paramtypes, typelist) == true)
                    found_pos = (*insert_pos);
                ++(*insert_pos);
            }

            for(int i = mid - 1; found_pos == -1 && i >= 0 && strcmp(name, list->elements[i].name) == 0; --i)
                if(TypeList_equal(&list->elements[i].paramtypes, typelist) == 0)
                    found_pos = i;

            return found_pos;
        }

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
        int new_capacity = 1 + list->capacity * 2;
        Function* new_list = realloc(list->elements, new_capacity * sizeof(list->elements[0]));
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

int FunctionList_insertAt(FunctionList* itemlist, char* name, int name_length, int scope_level, const Type* return_type, TypeList* paramtypes,
                          int decl_line, int decl_column, int position)
{
    Function element;

    element.name         = name;
    element.name_length  = name_length;
    element.scope_level  = scope_level;
    element.return_type  = (*return_type);
    element.paramtypes   = (*paramtypes);
    element.decl_line    = decl_line;
    element.decl_column  = decl_column;

    if(FunctionList_insertElement(itemlist, &element, position) == -1)
        return -1;

    return 0;
}

int FunctionList_insert(FunctionList* list, char* name, int name_length, int scope_level, const Type* return_type, TypeList* paramtypes,
                        int decl_line, int decl_column)
{
    int position;
    if(FunctionList_find(list, name, paramtypes, &position) != -1)
        return 1;

    return FunctionList_insertAt(list, name, name_length, scope_level, return_type, paramtypes, decl_line, decl_column, position);
}

int FunctionList_replace(FunctionList* list, char* name, int name_length, int scope_level,  const Type* return_type, TypeList* paramtypes,
                         int decl_line, int decl_column, int position)
{
    Function* element = &list->elements[position];

    element->name        = name;
    element->name_length = name_length;
    element->scope_level = scope_level;
    element->return_type = (*return_type);
    element->paramtypes  = (*paramtypes);
    element->decl_line   = decl_line;
    element->decl_column = decl_column;

    return 0;
}



/* FunctionListStack */
void FunctionListStack_clear(FunctionListStack* stack)
{
    for(int i = 0; i < stack->size; ++i)
        FunctionList_clear(&stack->elements[i], i);

    free(stack->elements);
    stack->elements = NULL;
    stack->capacity = 0;
    stack->size = 0;
}

int FunctionListStack_push(FunctionListStack* stack, const FunctionList* list)
{
    if(stack->size == stack->capacity)
    {
        int new_capacity = 1 + stack->capacity * 2;
        FunctionList* new_stack = realloc(stack->elements, new_capacity * sizeof(stack->elements[0]));
        if(new_stack == NULL)
        {
            int new_capacity = 1 + stack->capacity;
            new_stack = realloc(stack->elements, new_capacity * sizeof(stack->elements[0]));
            if(new_stack == NULL)
                return -1;
        }

        stack->elements = new_stack;
        stack->capacity = new_capacity;
    }

    if(FunctionList_copy(list, &stack->elements[stack->size]) != 0)
        return -1;

    ++stack->size;
    return 0;
}

int FunctionListStack_pop(FunctionListStack* stack, FunctionList* list)
{
    if(stack->size == 0)
        return -1;

    --stack->size;
    FunctionList_clear(list, scope_level);
    (*list) = stack->elements[stack->size];
    return 0;
}

FunctionList* FunctionListStack_top(FunctionListStack* stack)
{
    if(stack->size == 0)
        return NULL;
    return &stack->elements[stack->size - 1];
}



/* Expression */
void Expression_set(Expression* exp, const Type* type, Variable* variable, void* data)
{
    exp->variable = variable;

    if(variable == NULL)
    {
        if(type == NULL)
            exp->type = Type_invalid;
        else
        {
            exp->type = (*type);

            switch(type->type)
            {
            case INT:    exp->intval    = *((int*)   data); break;
            case BOOL:   exp->boolval   = *((bool*)  data); break;
            case DOUBLE: exp->doubleval = *((double*)data); break;
            case CHAR:   exp->charval   = *((char*)  data); break;
            case STRING: exp->strval    = *((char**) data); break;
            }
        }
    }
    else
    {
        exp->type = variable->type;

        switch(variable->type.type)
        {
        case INT:    exp->intval    = variable->intval;    break;
        case BOOL:   exp->boolval   = variable->boolval;   break;
        case DOUBLE: exp->doubleval = variable->doubleval; break;
        case CHAR:   exp->charval   = variable->charval;   break;
        case STRING: exp->strval    = variable->strval;    break;
        }
    }
}
void Expression_reset(Expression* exp)
{
    exp->type = Type_invalid;
    exp->variable = NULL;
}
void Expression_clear(Expression* exp)
{
    if(exp->variable == NULL)
    {
        if(exp->type.type == STRING)
            free(exp->strval);
        else if(exp->type.type == CLASS)
            free(exp->type.class_name);
    }

    Expression_reset(exp);
}

void Expression_assign(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->variable == NULL || lval->variable->constant == true)
    {
        yyerror("the left operand of '=' must be a lval");
        return;
    }
    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '=' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    lval->variable->intval    = rval->intval;    break;
    case BOOL:   lval->variable->boolval   = rval->boolval;   break;
    case DOUBLE: lval->variable->doubleval = rval->doubleval; break;
    case CHAR:   lval->variable->charval   = rval->charval;   break;
    case STRING: free(lval->variable->strval); lval->variable->strval = rval->strval; break;
    case CLASS:  break;
    }

    (*result) = (*lval);
}

void Expression_addassign(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->variable == NULL || lval->variable->constant == true)
    {
        yyerror("the left operand of '+=' must be a lval");
        return;
    }
    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '+=' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    lval->variable->intval    += rval->variable->intval;    break;
    case BOOL:   lval->variable->boolval   += rval->variable->boolval;   break;
    case DOUBLE: lval->variable->doubleval += rval->variable->doubleval; break;
    case CHAR:   lval->variable->charval   += rval->variable->charval;   break;
    case STRING: appendString(lval->variable->strval, rval->variable->strval); break;
    case CLASS:  yyerror("addition is an invalid operation for %s", lval->type.class_name); break;
    }

    (*result) = (*lval);
}
void Expression_subassign(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->variable == NULL || lval->variable->constant == true)
    {
        yyerror("the left operand of '-=' must be a lval");
        return;
    }
    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '-=' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    lval->variable->intval    -= rval->variable->intval;    break;
    case BOOL:   lval->variable->boolval   -= rval->variable->boolval;   break;
    case DOUBLE: lval->variable->doubleval -= rval->variable->doubleval; break;
    case CHAR:   lval->variable->charval   -= rval->variable->charval;   break;
    case STRING: yyerror("substraction is an invalid operation for string"); break;
    case CLASS:  yyerror("substraction is an invalid operation for %s", lval->type.class_name); break;
    }

    (*result) = (*lval);
}
void Expression_mulassign(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->variable == NULL || lval->variable->constant == true)
    {
        yyerror("the left operand of '*=' must be a lval");
        return;
    }
    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '*=' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    lval->variable->intval    *= rval->variable->intval;    break;
    case BOOL:   lval->variable->boolval    = lval->variable->boolval && rval->variable->boolval; break;
    case DOUBLE: lval->variable->doubleval *= rval->variable->doubleval; break;
    case CHAR:   lval->variable->charval   *= rval->variable->charval;   break;
    case STRING: yyerror("multiplication is an invalid operation for string"); break;
    case CLASS:  yyerror("multiplication is an invalid operation for %s", lval->type.class_name); break;
    }

    (*result) = (*lval);
}
void Expression_divassign(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->variable == NULL || lval->variable->constant == true)
    {
        yyerror("the left operand of '/=' must be a lval");
        return;
    }
    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '/=' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    lval->variable->intval    /= rval->variable->intval;    break;
    case BOOL:   yyerror("division is an invalid operation for bool");   break;
    case DOUBLE: lval->variable->doubleval /= rval->variable->doubleval; break;
    case CHAR:   lval->variable->charval   /= rval->variable->charval;   break;
    case STRING: yyerror("division is an invalid operation for string"); break;
    case CLASS:  yyerror("division is an invalid operation for %s", lval->type.class_name); break;
    }

    (*result) = (*lval);
}
void Expression_modassign(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->variable == NULL || lval->variable->constant == true)
    {
        yyerror("the left operand of '%%=' must be a lval");
        return;
    }
    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '%%=' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    lval->variable->intval  %= rval->variable->intval;     break;
    case BOOL:   yyerror("modulus is an invalid operation for bool");   break;
    case DOUBLE: yyerror("modulus is an invalid operation for double"); break;
    case CHAR:   lval->variable->charval %= rval->variable->charval;    break;
    case STRING: yyerror("modulus is an invalid operation for string"); break;
    case CLASS:  yyerror("modulus is an invalid operation for %s", lval->type.class_name); break;
    }

    (*result) = (*lval);
}

void Expression_add(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '+' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    {long   x = lval->intval    + rval->intval;    Expression_set(result, &lval->type, NULL, &x);} break;
    case BOOL:   {bool   x = lval->boolval  != rval->boolval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case DOUBLE: {double x = lval->doubleval + rval->doubleval; Expression_set(result, &lval->type, NULL, &x);} break;
    case CHAR:   {char   x = lval->charval   + rval->charval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case STRING: {char*  x = concatStrings(lval->strval, rval->strval); Expression_set(result, &lval->type, NULL, &x); break;}
    case CLASS: yyerror("addition is an invalid operation for %s", lval->type.class_name); break;
    }
}
void Expression_sub(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '-' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    {long   x = lval->intval    - rval->intval;    Expression_set(result, &lval->type, NULL, &x);} break;
    case BOOL:   {bool   x = lval->boolval  != rval->boolval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case DOUBLE: {double x = lval->doubleval - rval->doubleval; Expression_set(result, &lval->type, NULL, &x);} break;
    case CHAR:   {char   x = lval->charval   - rval->charval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case STRING: yyerror("substraction is an invalid operation for string"); break;
    case CLASS:  yyerror("substraction is an invalid operation for %s", lval->type.class_name); break;
    }
}
void Expression_mul(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '*' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    {long   x = lval->intval    * rval->intval;    Expression_set(result, &lval->type, NULL, &x);} break;
    case BOOL:   {bool   x = lval->boolval  && rval->boolval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case DOUBLE: {double x = lval->doubleval * rval->doubleval; Expression_set(result, &lval->type, NULL, &x);} break;
    case CHAR:   {char   x = lval->charval   * rval->charval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case STRING: yyerror("multiplication is an invalid operation for string"); break;
    case CLASS:  yyerror("multiplication is an invalid operation for %s", lval->type.class_name); break;
    }
}
void Expression_div(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '/' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    {long   x = lval->intval    / rval->intval;    Expression_set(result, &lval->type, NULL, &x);} break;
    case BOOL:   yyerror("division is an invalid operation for bool");                      break;
    case DOUBLE: {double x = lval->doubleval / rval->doubleval; Expression_set(result, &lval->type, NULL, &x);} break;
    case CHAR:   {char   x = lval->charval   / rval->charval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case STRING: yyerror("division is an invalid operation for string");                    break;
    case CLASS:  yyerror("division is an invalid operation for %s", lval->type.class_name); break;
    }
}
void Expression_mod(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '%%' must have the same type");
        return;
    }

    switch(lval->type.type)
    {
    case INT:    {long   x = lval->intval    / rval->intval;    Expression_set(result, &lval->type, NULL, &x);} break;
    case BOOL:   yyerror("modulus is an invalid operation for bool");                      break;
    case DOUBLE: yyerror("modulus is an invalid operation for double");                    break;
    case CHAR:   {char   x = lval->charval   / rval->charval;   Expression_set(result, &lval->type, NULL, &x);} break;
    case STRING: yyerror("modulus is an invalid operation for string");                    break;
    case CLASS:  yyerror("modulus is an invalid operation for %s", lval->type.class_name); break;
    }
}
void Expression_neg(const Expression* val, Expression* result)
{
    Expression_clear(result);
    if(val->type.type == INVAL_TYPE)
        return;

    switch(val->type.type)
    {
    case INT:    {long   x = -val->intval;    Expression_set(result, &val->type, NULL, &x);} break;
    case BOOL:   {bool   x = -val->boolval;   Expression_set(result, &val->type, NULL, &x);} break;
    case DOUBLE: {double x = -val->doubleval; Expression_set(result, &val->type, NULL, &x);} break;
    case CHAR:   {char   x = -val->charval;   Expression_set(result, &val->type, NULL, &x);} break;
    case STRING: yyerror("unary minus is an invalid operation for string");                   break;
    case CLASS:  yyerror("unary minus is an invalid operation for %s", val->type.class_name); break;
    }
}

void Expression_preinc(const Expression* val, Expression* result)
{
    Expression_clear(result);
    if(val->type.type == INVAL_TYPE)
        return;

    if(val->variable == NULL || val->variable->constant == true)
    {
        yyerror("operand of '++X' must be a lval");
        return;
    }

    switch(val->type.type)
    {
    case INT:    ++val->variable->intval;    break;
    case BOOL:   ++val->variable->boolval;   break;
    case DOUBLE: ++val->variable->doubleval; break;
    case CHAR:   ++val->variable->charval;   break;
    case STRING: yyerror("preincrement is an invalid operation for string"); break;
    case CLASS:  yyerror("preincrement is an invalid operation for %s", val->type.class_name); break;
    }

    (*result) = (*val);
}
void Expression_predec(const Expression* val, Expression* result)
{
    Expression_clear(result);
    if(val->type.type == INVAL_TYPE)
        return;

    if(val->variable == NULL || val->variable->constant == true)
    {
        yyerror("operand of '--X' must be a lval");
        return;
    }

    switch(val->type.type)
    {
    case INT:    --val->variable->intval;    break;
    case BOOL:   --val->variable->boolval;   break;
    case DOUBLE: --val->variable->doubleval; break;
    case CHAR:   --val->variable->charval;   break;
    case STRING: yyerror("predecrement is an invalid operation for string"); break;
    case CLASS:  yyerror("predecrement is an invalid operation for %s", val->type.class_name); break;
    }

    (*result) = (*val);
}
void Expression_postinc(const Expression* val, Expression* result)
{
    Expression_clear(result);
    if(val->type.type == INVAL_TYPE)
        return;

    if(val->variable == NULL || val->variable->constant == true)
    {
        yyerror("operand of 'X++' must be a lval");
        return;
    }

    switch(val->type.type)
    {
    case INT:    Expression_set(result, &val->type, NULL, &val->variable->intval);    ++val->variable->intval;    break;
    case BOOL:   Expression_set(result, &val->type, NULL, &val->variable->boolval);   ++val->variable->boolval;   break;
    case DOUBLE: Expression_set(result, &val->type, NULL, &val->variable->doubleval); ++val->variable->doubleval; break;
    case CHAR:   Expression_set(result, &val->type, NULL, &val->variable->charval);   ++val->variable->charval;   break;
    case STRING: yyerror("postincrement is an invalid operation for string"); break;
    case CLASS:  yyerror("postincrement is an invalid operation for %s", val->type.class_name); break;
    }
}
void Expression_postdec(const Expression* val, Expression* result)
{
    Expression_clear(result);
    if(val->type.type == INVAL_TYPE)
        return;

    if(val->variable == NULL || val->variable->constant == true)
    {
        yyerror("operand of 'X--' must be a lval");
        return;
    }

    switch(val->type.type)
    {
    case INT:    Expression_set(result, &val->type, NULL, &val->variable->intval);    --val->variable->intval;    break;
    case BOOL:   Expression_set(result, &val->type, NULL, &val->variable->boolval);   --val->variable->boolval;   break;
    case DOUBLE: Expression_set(result, &val->type, NULL, &val->variable->doubleval); --val->variable->doubleval; break;
    case CHAR:   Expression_set(result, &val->type, NULL, &val->variable->charval);   --val->variable->charval;   break;
    case STRING: yyerror("postdecrement is an invalid operation for string"); break;
    case CLASS:  yyerror("postdecrement is an invalid operation for %s", val->type.class_name); break;
    }
}

void Expression_not(const Expression* val, Expression* result)
{
    Expression_clear(result);
    if(val->type.type == INVAL_TYPE)
        return;

    switch(val->type.type)
    {
    case INT:    {long   x = !val->intval;    Expression_set(result, &val->type, NULL, &x);} break;
    case BOOL:   {bool   x = !val->boolval;   Expression_set(result, &val->type, NULL, &x);} break;
    case DOUBLE: {double x = !val->doubleval; Expression_set(result, &val->type, NULL, &x);} break;
    case CHAR:   {char   x = !val->charval;   Expression_set(result, &val->type, NULL, &x);} break;
    case STRING: yyerror("'!' is an invalid operation for string");                   break;
    case CLASS:  yyerror("'!' is an invalid operation for %s", val->type.class_name); break;
    }
}
void Expression_and(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->type.type == CLASS)
    {
        yyerror("conversion to bool is an invalid operation for %s", lval->type.class_name);
        return;
    }
    if(rval->type.type == CLASS)
    {
        yyerror("conversion to bool is an invalid operation for %s", rval->type.class_name);
        return;
    }

    bool x = Expression_getBool(lval) && Expression_getBool(rval);
    Expression_set(result, &Type_bool, NULL, &x);
}
void Expression_or(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(lval->type.type == CLASS)
    {
        yyerror("conversion to bool is an invalid operation for %s", lval->type.class_name);
        return;
    }
    if(rval->type.type == CLASS)
    {
        yyerror("conversion to bool is an invalid operation for %s", rval->type.class_name);
        return;
    }

    bool x = Expression_getBool(lval) || Expression_getBool(rval);
    Expression_set(result, &Type_bool, NULL, &x);
}

void Expression_eq(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '==' must have the same type");
        return;
    }

    bool x;

    switch(lval->type.type)
    {
    case INT:    x = (lval->intval    == rval->intval);         break;
    case BOOL:   x = (lval->boolval   == rval->boolval);        break;
    case DOUBLE: x = (lval->doubleval == rval->doubleval);      break;
    case CHAR:   x = (lval->charval   == rval->charval);        break;
    case STRING: x = (compareStrings(lval->strval, rval->strval) == 0); break;
    case CLASS: yyerror("'==' is an invalid operation for %s", lval->type.class_name); break;
    }

    Expression_set(result, &Type_bool, NULL, &x);
}
void Expression_neq(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '!=' must have the same type");
        return;
    }

    bool x;

    switch(lval->type.type)
    {
    case INT:    x = (lval->intval    != rval->intval);         break;
    case BOOL:   x = (lval->boolval   != rval->boolval);        break;
    case DOUBLE: x = (lval->doubleval != rval->doubleval);      break;
    case CHAR:   x = (lval->charval   != rval->charval);        break;
    case STRING: x = (compareStrings(lval->strval, rval->strval) != 0); break;
    case CLASS: yyerror("'!=' is an invalid operation for %s", lval->type.class_name); break;
    }

    Expression_set(result, &Type_bool, NULL, &x);
}
void Expression_leq(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '<=' must have the same type");
        return;
    }

    bool x;

    switch(lval->type.type)
    {
    case INT:    x = (lval->intval    <= rval->intval);         break;
    case BOOL:   x = (lval->boolval   <= rval->boolval);        break;
    case DOUBLE: x = (lval->doubleval <= rval->doubleval);      break;
    case CHAR:   x = (lval->charval   <= rval->charval);        break;
    case STRING: x = (compareStrings(lval->strval, rval->strval) <= 0); break;
    case CLASS: yyerror("'<=' is an invalid operation for %s", lval->type.class_name); break;
    }

    Expression_set(result, &Type_bool, NULL, &x);
}
void Expression_geq(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '>=' must have the same type");
        return;
    }

    bool x;

    switch(lval->type.type)
    {
    case INT:    x = (lval->intval    >= rval->intval);         break;
    case BOOL:   x = (lval->boolval   >= rval->boolval);        break;
    case DOUBLE: x = (lval->doubleval >= rval->doubleval);      break;
    case CHAR:   x = (lval->charval   >= rval->charval);        break;
    case STRING: x = (compareStrings(lval->strval, rval->strval) >= 0); break;
    case CLASS: yyerror("'>=' is an invalid operation for %s", lval->type.class_name); break;
    }

    Expression_set(result, &Type_bool, NULL, &x);
}
void Expression_low(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '<' must have the same type");
        return;
    }

    bool x;

    switch(lval->type.type)
    {
    case INT:    x = (lval->intval    < rval->intval);         break;
    case BOOL:   x = (lval->boolval   < rval->boolval);        break;
    case DOUBLE: x = (lval->doubleval < rval->doubleval);      break;
    case CHAR:   x = (lval->charval   < rval->charval);        break;
    case STRING: x = (compareStrings(lval->strval, rval->strval) < 0); break;
    case CLASS: yyerror("'<' is an invalid operation for %s", lval->type.class_name); break;
    }

    Expression_set(result, &Type_bool, NULL, &x);
}
void Expression_gre(const Expression* lval, const Expression* rval, Expression* result)
{
    Expression_clear(result);
    if(lval->type.type == INVAL_TYPE || rval->type.type == INVAL_TYPE)
        return;

    if(Type_equal(&lval->type, &rval->type) == false)
    {
        yyerror("the operands of '>' must have the same type");
        return;
    }

    bool x;

    switch(lval->type.type)
    {
    case INT:    x = (lval->intval    > rval->intval);         break;
    case BOOL:   x = (lval->boolval   > rval->boolval);        break;
    case DOUBLE: x = (lval->doubleval > rval->doubleval);      break;
    case CHAR:   x = (lval->charval   > rval->charval);        break;
    case STRING: x = (compareStrings(lval->strval, rval->strval) > 0); break;
    case CLASS: yyerror("'>' is an invalid operation for %s", lval->type.class_name); break;
    }

    Expression_set(result, &Type_bool, NULL, &x);
}



bool Expression_getBool(const Expression* val)
{
    switch(val->type.type)
    {
    case INT:    return val->intval;                   break;
    case BOOL:   return val->boolval;                  break;
    case DOUBLE: return val->doubleval;                break;
    case CHAR:   return val->charval;                  break;
    case STRING: return val->strval && val->strval[0]; break;
    default:
        yyerror("debug: Expression_getBool: expression is invalid");
        abort();
    }
}
