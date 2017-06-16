%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include "calc.h"

typeNode *opr(int oper, int nops, ...);
typeNode *id(double i);
typeNode *con(double value);

void freeNode(typeNode *p);
double interprete(typeNode *p);
int yylex(void);
extern int ifing;
void yyerror(char *s);
double sym[26];
%}

%union {
    double dValue;
    char sIndex;               
    typeNode *nPtr;             
};

%token <dValue> DINTEGER INTEGER
%token <sIndex> VARIABLE
%token WHILE IF PRINT
%token END
%nonassoc IFX
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <nPtr> stmt expr stmt_list

%%

program:
        function                { exit(0); }
        ;

function:
          function stmt         { interprete($2); freeNode($2); }
        | 
        ;

stmt:                                   
          ';'                            { $$ = opr(';', 2, NULL, NULL); }
        | expr ';'                       { $$ = opr(PRINT, 1, $1); }
        | VARIABLE '=' expr ';'          { $$ = opr('=', 2, id($1), $3);}
        | WHILE '(' expr ')' stmt_list END    { $$ = opr(WHILE, 2, $3, $5); }
        | IF '(' expr ')' stmt_list END %prec IFX { $$ = opr(IF, 2, $3, $5); }
        | IF '(' expr ')' stmt_list ELSE stmt_list END { $$ = opr(IF, 3, $3, $5, $7); }
        ;

stmt_list:
          stmt                  { $$ = $1; }
        | stmt_list stmt        { $$ = opr(';', 2, $1, $2); }
        ;

expr:
          INTEGER               { $$ = con($1);}
        | DINTEGER              { $$ = con($1);}
        | VARIABLE              { $$ = id($1); }
        | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
        | expr '+' expr         { $$ = opr('+', 2, $1, $3); }
        | expr '-' expr         { $$ = opr('-', 2, $1, $3); }
        | expr '*' expr         { $$ = opr('*', 2, $1, $3); }
        | expr '/' expr         { $$ = opr('/', 2, $1, $3); }
        | expr '<' expr         { $$ = opr('<', 2, $1, $3); }
        | expr '>' expr         { $$ = opr('>', 2, $1, $3); }
        | expr GE expr          { $$ = opr(GE, 2, $1, $3); }
        | expr LE expr          { $$ = opr(LE, 2, $1, $3); }
        | expr NE expr          { $$ = opr(NE, 2, $1, $3); }
        | expr EQ expr          { $$ = opr(EQ, 2, $1, $3); }
        | '(' expr ')'          { $$ = $2; }
        ;

%%

typeNode *con(double value) {
    typeNode *p;

    if ((p = malloc(sizeof(typeNode))) == NULL)
        yyerror("out of memory");

    p->type = typeCon;
    p->con.value = value;

    return p;
}

typeNode *id(double i) {
    typeNode *p;

    if ((p = malloc(sizeof(typeNode))) == NULL)
        yyerror("out of memory");

    p->type = typeId;
    p->id.i = i;
    return p;
}

typeNode *opr(int oper, int nops, ...) {
    va_list ap;
    typeNode *p;
    int i;

    if ((p = malloc(sizeof(typeNode) + (nops-1) * sizeof(typeNode *))) == NULL)
        yyerror("out of memory");

    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for (i = 0; i < nops; i++)
        p->opr.op[i] = va_arg(ap, typeNode*);
    va_end(ap);
    return p;
}

void freeNode(typeNode *p) {
    int i;

    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->opr.nops; i++)
            freeNode(p->opr.op[i]);
    }
    free (p);
}

double interprete(typeNode *p) {
    if (!p) return 0;
    switch(p->type) {
    case typeCon:       return p->con.value;
    case typeId:        return sym[p->id.i];
                        
    case typeOpr:
        switch(p->opr.oper) {
        case WHILE:     while(interprete(p->opr.op[0])) interprete(p->opr.op[1]); return 0;
        case IF:        if (interprete(p->opr.op[0])){
                            ifing = 0;
                            printf("IF\n");
                            interprete(p->opr.op[1]);
                            return 0;
                        }
                        else if (p->opr.nops > 2){
                            ifing = 0; 
                            printf("IF\n");
                            interprete(p->opr.op[2]);
                            return 0;
                        }
        case PRINT:     printf("%.1f\n", interprete(p->opr.op[0])); return 0;
                        
        case ';':       interprete(p->opr.op[0]); return interprete(p->opr.op[1]);
        case '=':       printf("%.1f\n", interprete(p->opr.op[1]));
                        return sym[p->opr.op[0]->id.i] = interprete(p->opr.op[1]);

        case UMINUS:    return -interprete(p->opr.op[0]);
        case '+':       return interprete(p->opr.op[0]) + interprete(p->opr.op[1]);
        case '-':       return interprete(p->opr.op[0]) - interprete(p->opr.op[1]);
        case '*':       return interprete(p->opr.op[0]) * interprete(p->opr.op[1]);
        case '/':       return interprete(p->opr.op[0]) / interprete(p->opr.op[1]);
        case '<':       return interprete(p->opr.op[0]) < interprete(p->opr.op[1]);
        case '>':       return interprete(p->opr.op[0]) > interprete(p->opr.op[1]);
        case GE:        return interprete(p->opr.op[0]) >= interprete(p->opr.op[1]);
        case LE:        return interprete(p->opr.op[0]) <= interprete(p->opr.op[1]);
        case NE:        return interprete(p->opr.op[0]) != interprete(p->opr.op[1]);
        case EQ:        return interprete(p->opr.op[0]) == interprete(p->opr.op[1]);
        }
    }
    return 0;
}

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

void prompt(){
  printf("?- ");
}

int main(void) {
    prompt();
    while(1){
      yyparse();
    }
    return 0;
}
