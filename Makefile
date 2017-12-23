RM := rm -f

NAME := tema

CC   := gcc
LEX  := lex
YACC := yacc

CCFLAGS   := -O3
LEXFLAGS  := --yylineno
YACCFLAGS := -d

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

$(OUTYACC): $(SRCYACC)
	$(YACC) -o $@ $(YACCFLAGS) $(SRCYACC)



clean:
	@$(RM) $(NAME) $(OUTLEX) $(OUTYACC)

.PHONY: all clean # These targets don't represent files
