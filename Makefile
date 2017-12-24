RM := rm -f

NAME := tema

CC   := gcc
LEX  := flex
YACC := bison

CCFLAGS   := -O3
LEXFLAGS  :=
YACCFLAGS := --yacc

SRCLEX  := $(NAME).l
SRCYACC := $(NAME).y
OUTLEX  := lex.yy.c
OUTYACC := y.tab.c



################################################################
########################### Targets ############################
################################################################
all: $(NAME)

$(NAME): $(OUTLEX) $(OUTYACC)
	$(CC) -o $@ $(CCFLAGS) $^ -ll -ly

$(OUTLEX): $(SRCLEX)
	$(LEX) -o $@ $(LEXFLAGS) $(SRCLEX)

$(OUTYACC): $(SRCYACC) String.h
	$(YACC) -o $@ $(YACCFLAGS) $(SRCYACC)



clean:
	@$(RM) $(NAME) $(OUTLEX) $(OUTYACC) $(OUTYACC:.c=.h)



test: all
	@./$(NAME) < test.txt



.PHONY: all clean test # These targets don't represent files
