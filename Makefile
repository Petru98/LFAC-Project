RM := rm -f

NAME := tema

CC   := gcc
LEX  := flex
YACC := bison

CCFLAGS   := -ggdb
LEXFLAGS  :=
YACCFLAGS :=

SRCLEX  := $(NAME).l
SRCYACC := $(NAME).y
OUTLEX  := lex.yy.c
OUTYACC := y.tab.c
SRCS    := util.c
HEADERS := $(SRCS:.c=.h)



################################################################
########################### Targets ############################
################################################################
all: $(NAME)

$(NAME): $(OUTLEX) $(OUTYACC) $(SRCS)
	$(CC) -o $@ $(CCFLAGS) $^ -ll -ly

$(OUTLEX): $(SRCLEX) $(HEADERS)
	$(LEX) -o $@ $(LEXFLAGS) $(SRCLEX)

$(OUTYACC): $(SRCYACC) $(HEADERS)
	$(YACC) -o $@ $(YACCFLAGS) $(SRCYACC)



clean:
	@$(RM) $(NAME) $(OUTLEX) $(OUTYACC) $(OUTYACC:.c=.h)



test: all
	@./$(NAME) test.txt



.PHONY: all clean test # These targets don't represent files
