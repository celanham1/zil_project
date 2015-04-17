%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

extern int turn;
extern char* title;
extern char* author;
extern char* release;
extern char* sdesc;
extern int poisoned;
extern int poison_counter;
extern int wounded;
extern int wound_counter;
extern int numQue;
struct operation{
	char* str;
	int num;
	int counter;
	char* routine_call;
	int verb;
	int equal;
	int remove;
	int tell;
	int set;
	int setg;
};
struct cond{
	int numOperations;
	struct operation condition;		
	struct operation operations[10];	
};
extern struct statement{
	struct operation operstmt;
	struct cond condstmt;
}x;
extern struct routine{
	char* name;
	int numStmts;
	struct statement stmts[10]; 
}queue[10];
//extern struct routine ;
extern struct room{
	char* name;
	char* desc;
	char* ldesc;
}current;
extern doStatements(struct statement *,int);

%}
%s USER
Letter [A-Za-z]
Digit [0-9]
Number {Digit}+(\.{Digit}+)?
Punctuation [-.'_]
Word {Letter}({Letter}|{Punctuation})*
String "\""([^"\""]+)"\""
Math "+"|"-"|"*"|"%"
%%
"<"			{return(LB);}
">"			{return(RB);}
"("			{return(LP);}
")"			{return(RP);}
","			{return(COMMA);}
"TITLE"			{return(TITLE);}
"AUTHOR"		{return(AUTHOR);}
"RELEASE"		{return(RELEASE);}
"STORYDESC"		{return(STORYDESC);}
"ROOM"			{return(ROOM);}
"LOC"			{return(LOC);}
"DESC"			{return(DESC);}
"LDESC"			{return(LDESC);}
"NORTH"			{return(NORTH);}
"EAST"			{return(EAST);}
"WEST"			{return(WEST);}
"SOUTH"			{return(SOUTH);}
"UP"			{return(UP);}
"DOWN"			{return(DOWN);}
"TO"			{return(TO);}
"OBJECT"		{return(OBJECT);}
"ADJECTIVE"		{return(ADJECTIVE);}
"ACTION"		{return(ACTION);}
"SET"			{return(SET);}
"SETG"			{return(SETG);}
"ROUTINE"		{return(ROUTINE);}
"REMOVE"		{return(REMOVE);}
"COND"			{return(COND);}
"TELL"			{return(TELL);}
"VERB?"			{return(VERB);}
"EQUAL?"		{return(EQUAL);}
"UNDERSTAND"		{return(UNDERSTAND);}
<USER>"north"|"n"	{return(NORTH);}
<USER>"south"|"s"	{return(SOUTH);}
<USER>"east"|"e"	{return(EAST);}
<USER>"west"|"w"	{return(WEST);}
<USER>"up"|"u"		{return(UP);}
<USER>"down"|"d" 	{return(DOWN);}
<USER>"look"		{return(LOOK);}
<USER>"inventory"	{return(INVENTORY);} 
<USER>"eat"		{return(EAT);}
<USER>"drop"		{return(DROP);}
<USER>"take"		{return(TAKE);}
<USER>"stomp"		{return(STOMP);}
<USER>"burninate" 	{return(BURNINATE);}
<USER>"throw"		{return(THROW);}
<USER>"quit"		{return 0;}
<USER>\n		{
				int i;
				for(i=0;i<numQue;i++){
					doStatements(queue[i].stmts,queue[i].numStmts);
				}
				if(poisoned==1) poison_counter++;
				else if(wounded==1) wound_counter++;
				printf(">");}
<USER>[ \t]+		/*Empty*/
{Math}			{return(MATH);}
{Word}			{yylval.string=strdup(yytext); return(WORD);}
{String}		{char *x = yytext+1; x[strlen(x)-1]='\0'; yylval.string=strdup(x); return(STRING);}
{Number}		{yylval.val=atoi(strdup(yytext)); return(NUM);}			
<INITIAL>[ \t\n]+	/*Empty*/
<<EOF>>			{	yypop_buffer_state();
				yyin = stdin;
				yypush_buffer_state(yy_create_buffer(yyin,YY_BUF_SIZE));
				BEGIN USER;
				printf("%s\nAn interactive fiction by %s\n%s\n",title,author,release);
				if(sdesc!='\0') printf("%s\n%s\n%s\n",sdesc,current.desc,current.ldesc);
				else printf("%s\n%s\n",current.desc,current.ldesc);
				printf(">");
				turn++;
			}

%%



