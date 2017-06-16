%{
#include <stdlib.h>
#include "calc.h"
#include "y.tab.h"
void yyerror(char *);
int ifing = 0;
%}

%%

[a-z]       { 
                yylval.sIndex = *yytext - 'a';
                return VARIABLE;
            }

0           {
                yylval.dValue = atoi(yytext);
                return INTEGER;
            }

[1-9][0-9]* {
                yylval.dValue = atoi(yytext);
                return INTEGER;
            }


[0-9]+\.[0-9]+ {
                yylval.dValue = atof(yytext);
                return DINTEGER; 
               }

[-()<>=+*/;{}.] {
                return *yytext;
             }

">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
"while"         ifing = 1; return WHILE;
"if"            ifing = 1; return IF;
"else"          return ELSE;
"end"           ifing = 0; return END; 
"print"         return PRINT;
"\n"            if(ifing){printf("> ");};if(!ifing){printf("?- ");};  
[ \t]+          ;      

.               yyerror("lexical error");
%%
int yywrap(void) {
    return 1;
}
