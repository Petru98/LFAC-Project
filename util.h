#ifndef INCLUDED_ITEM_H
#define INCLUDED_ITEM_H

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void yyerror(const char* msg, ...);
void yywarning(const char* msg, ...);



/* Memory */
void* memdup(const void* mem, size_t size);



/* Type */
typedef struct Type
{
    int type;
    char* class_name;
} Type;

const Type Type_invalid;
const Type Type_int;
const Type Type_bool;
const Type Type_double;
const Type Type_char;
const Type Type_string;
const Type Type_void;

bool Type_equal(const Type* lval, const Type* rval);



typedef struct TypeList
{
    Type* elements;
    int size;
    int capacity;
} TypeList;

void TypeList_destroy(TypeList* list);
int  TypeList_insert(TypeList* list, Type* element);
bool TypeList_equal(const TypeList* llist, const TypeList* rlist);



/* Variable */
typedef struct Variable
{
    char* name;
    int name_length;
    Type type;
    int scope_level;
    int decl_line;
    int decl_column;
    bool constant;
    bool initialized;

    union
    {
        long intval;
        bool boolval;
        double doubleval;
        char charval;
        char* strval;
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
int  VariableList_find(const VariableList* list, const char* name, int* insert_pos);
int  VariableList_insertElement(VariableList* list, Variable* element, int position);

int  VariableList_insertAt(VariableList* list, char* name, int name_length, const Type* type, int scope_level, bool constant, bool initialized,
                           int decl_line, int decl_column, int position);
int  VariableList_insert(VariableList* list, char* name, int name_length, const Type* type, int scope_level, bool constant, bool initialized,
                         int decl_line, int decl_column);
int  VariableList_replace(VariableList* list, char* name, int name_length, const Type* type, int scope_level, bool constant, bool initialized,
                          int decl_line, int decl_column, int position);



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
    char* name;
    int name_length;
    int scope_level;
    int decl_line;
    int decl_column;

    Type return_type;
    TypeList paramtypes;
} Function;

typedef struct FunctionList
{
    Function* elements;
    int size;
    int capacity;
} FunctionList;

void FunctionList_clear(FunctionList* list, int scope_level);
int  FunctionList_copy(const FunctionList* src, FunctionList* dst);
int  FunctionList_find(const FunctionList* list, const char* name, const TypeList* typelist, int* insert_pos);
int  FunctionList_insertElement(FunctionList* list, Function* element, int position);

int  FunctionList_insertAt(FunctionList* list, char* name, int name_length, int scope_level, const Type* return_type, TypeList* paramtypes,
                           int decl_line, int decl_column, int position);
int  FunctionList_insert(FunctionList* list, char* name, int name_length, int scope_level,  const Type* return_type, TypeList* paramtypes,
                         int decl_line, int decl_column);
int  FunctionList_replace(FunctionList* list, char* name, int name_length, int scope_level,  const Type* return_type, TypeList* paramtypes,
                          int decl_line, int decl_column, int position);



typedef struct FunctionListStack
{
    FunctionList* elements;
    int size;
    int capacity;
}FunctionListStack;

void FunctionListStack_clear(FunctionListStack* stack);
int  FunctionListStack_push(FunctionListStack* stack, const FunctionList* list);
int  FunctionListStack_pop(FunctionListStack* stack, FunctionList* list);
FunctionList* FunctionListStack_top(FunctionListStack* stack);



/* Expresion */
typedef struct Expression
{
    Type type;
    Variable* variable;

    union
    {
        long intval;
        bool boolval;
        double doubleval;
        char charval;
        char* strval;
    };
} Expression;

void Expression_set(Expression* exp, const Type* type, Variable* variable, void* data);
void Expression_reset(Expression* exp);
void Expression_clear(Expression* exp);

void Expression_assign(const Expression* lval, const Expression* rval, Expression* result);

void Expression_addassign(const Expression* lval, const Expression* rval, Expression* result);
void Expression_subassign(const Expression* lval, const Expression* rval, Expression* result);
void Expression_mulassign(const Expression* lval, const Expression* rval, Expression* result);
void Expression_divassign(const Expression* lval, const Expression* rval, Expression* result);
void Expression_modassign(const Expression* lval, const Expression* rval, Expression* result);

void Expression_add(const Expression* lval, const Expression* rval, Expression* result);
void Expression_sub(const Expression* lval, const Expression* rval, Expression* result);
void Expression_mul(const Expression* lval, const Expression* rval, Expression* result);
void Expression_div(const Expression* lval, const Expression* rval, Expression* result);
void Expression_mod(const Expression* lval, const Expression* rval, Expression* result);
void Expression_neg(const Expression* val, Expression* result);

void Expression_preinc (const Expression* val, Expression* result);
void Expression_predec (const Expression* val, Expression* result);
void Expression_postinc(const Expression* val, Expression* result);
void Expression_postdec(const Expression* val, Expression* result);

void Expression_not(const Expression* val, Expression* result);
void Expression_and(const Expression* lval, const Expression* rval, Expression* result);
void Expression_or (const Expression* lval, const Expression* rval, Expression* result);

void Expression_eq (const Expression* lval, const Expression* rval, Expression* result);
void Expression_neq(const Expression* lval, const Expression* rval, Expression* result);
void Expression_leq(const Expression* lval, const Expression* rval, Expression* result);
void Expression_geq(const Expression* lval, const Expression* rval, Expression* result);
void Expression_low(const Expression* lval, const Expression* rval, Expression* result);
void Expression_gre(const Expression* lval, const Expression* rval, Expression* result);



bool Expression_getBool(const Expression* val);
#endif
