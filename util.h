#ifndef INCLUDED_ITEM_H
#define INCLUDED_ITEM_H

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void* memdup(const void* mem, size_t size);

int strassign(char** dst, int* dst_capacity, const char* src);



/* Type */
typedef struct Type
{
    int type;
    char* class_name;
} Type;

typedef struct TypeList
{
    Type* elements;
    int size;
    int capacity;
} TypeList;

void TypeList_destroy(TypeList* list);
int  TypeList_insert(TypeList* list, Type* element);



/* Variable */
typedef struct Variable
{
    char* name;
    int name_length;
    int type;
    int scope_level;
    int decl_line;
    int decl_column;
    bool constant;

    union
    {
        int intval;
        bool boolval;
        double doubleval;
        char charval;
        char* strval;
        char* class_name;
    };
} Variable;

typedef struct VariableList
{
    Variable* elements;
    int size;
    int capacity;
} VariableList;

void VariableList_destroy(VariableList* list, int scope_level);
int  VariableList_copy(const VariableList* src, VariableList* dst);
int  VariableList_find(VariableList* list, const char* name, int* insert_pos);
int  VariableList_insertElement(VariableList* list, Variable* element, int position);
int  VariableList_insertAt(VariableList* list, char* name, int name_length, int type, int scope_level, bool constant, void* data, int decl_line, int decl_column, int position);
int  VariableList_insert(VariableList* list, char* name, int name_length, int type, int scope_level, bool constant, void* data, int decl_line, int decl_column);
int  VariableList_replace(VariableList* list, char* name, int name_length, int type, int scope_level, bool constant, void* data, int decl_line, int decl_column, int position);



typedef struct VariableListStack
{
    VariableList* elements;
    int size;
    int capacity;
}VariableListStack;

void VariableListStack_destroy(VariableListStack* stack);
int  VariableListStack_push(VariableListStack* stack, const VariableList* list);
int  VariableListStack_pop(VariableListStack* stack, VariableList* list);
VariableList* VariableListStack_top(VariableListStack* stack);



/* Function */
typedef struct Function
{
    int scope_level;
    int params_count;

    Type return_type;
    Type* params;

    int name_length;
    char name[];
} Function;

typedef struct FunctionList
{
    Function** elements;
    int size;
    int capacity;
} FunctionList;

void FunctionList_destroy(FunctionList* list);
int  FunctionList_find(FunctionList* list, const char* name, int* insert_pos);
int  FunctionList_insertElement(FunctionList* list, Function* element, int position);
int  FunctionList_insertAt(FunctionList* list, const char* name, int name_length, int scope_level, const Type* return_type, Type* params, int params_count, int position);
int  FunctionList_insert(FunctionList* list, const char* name, int name_length, int scope_level,  const Type* return_type, Type* params, int params_count);

#endif
