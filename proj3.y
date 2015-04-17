%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#define MAX_ROOMS 10
#define MAX_OBJECTS 10
#define MAX_ROUTINES 10
#define MAX_MAPS 10
#define MAX_CMDS 10
#define MAX_OPS 10
#define MAX_STMTS 10
extern FILE *yyin;
int yylex (void);
void yyerror (const char *str){
	fprintf(stderr,"error: %s\n",str);
}

struct object{
	char* name;
	char* desc;
	char* ldesc;
	char* adj;	
	char* loc;
	char* action;  //Name of the routine this object calls
};

//A structure that allows me to associate a number with an individual object
struct map{
	struct object obj;
	int num;
};

struct room{
	char* name;
	char* desc;
	char* ldesc;
	char* loc;
  	char* north;
	char* east;
	char* south;
	char* west;
  	char* up;
	char* down;
	int numObjs;
	struct object obj;
};

struct operation{
	char* str;
	int num;
	int counter;
	char* routine_call;
	/*Operation flags*/
	int verb;
	int equal;
	int remove;
	int tell;
	int set;
	int setg;
	
};

//Structure for conditional statement
struct cond{
	int numOperations;
	struct operation condition;		//Predicate
	struct operation operations[MAX_OPS];	//Clauses
};

//Statement holds either a operation or a conditional statement
struct statement{
	struct operation operstmt;
	struct cond condstmt;
};
struct routine{
	char* name;
	int numStmts;
	struct statement stmts[MAX_STMTS];
};
//Structure to hold a command created with UNDERSTAND 
struct command{
	char *name;
	int numStmts;
	struct statement stmts[MAX_STMTS];
};
//Game info
char* title;
char* author;
char* release;
char* sdesc;
//Counters and flags
int turn, poisoned, wounded;
int poison_counter, wound_counter;
char* currCmd; //Used with (VERB? WORD) operation
//Counters for the arrays
int numRooms = 0, numObjects = 0, numRoutines =0, numInv=0, numCmd=0, numStmt=0, numOps=0, numQue=0; 
struct map inventory[MAX_MAPS];
struct room rooms[MAX_ROOMS];
struct object objects[MAX_OBJECTS];
struct routine routines[MAX_ROUTINES];
struct command cmds[MAX_CMDS];
struct statement stmts[MAX_STMTS];
struct operation ops[MAX_OPS];
struct room current;
struct routine queue[MAX_ROUTINES];
//Temporary variables
struct room tempRoom;
struct object tempObject;
struct routine tempRoutine;
struct operation tempOperation;
struct cond tempCond;
struct statement tempStmt;
struct command tempCmd;
//Helper variables to clear a structure
struct room emptyRoom = {0};
struct object emptyO = {0};
struct routine emptyR = {0};
struct operation emptyOp = {0};
struct cond emptyC = {0};
struct map emptyM = {0};
struct statement emptyS = {0};
struct command emptyCmd = {0};

int x, y;
/*Checks if an item is in the inevntory  
@return the position*/
int inInv(char *name){
	for(x=0;x<numInv;x++){
		if(strcmp(inventory[x].obj.name,name)==0){
			return x;
		}
	}
	return -1;
}
//Deletes an item from the inventory
void deleteItemInv(char *name){
	int pos = inInv(name);
	if(inventory[pos].num<=0){
		if (pos< numInv-1) memmove(&inventory[pos], &inventory[pos+1], ((numInv-1)-pos) * sizeof inventory[0]);
		inventory[numInv-1] = emptyM;
		numInv--;
	}
}
//Changes a string to all uppercase
void allUpper(char *str){
	while(*str){
		*str=toupper(*str);
		str++;
	}
}
//Changes a string to all lowercase
void allLower(char *str){
	while(*str){
		*str=tolower(*str);
		str++;
	}
}
/*Performs a operation based on what flag is set
@return 0 if the operation was completed successfully*/
int doOperation(struct operation op){
	if(op.verb==1){			
		return strcmp(op.str,currCmd);
	}
	else if(op.remove==1){
		deleteItemInv(op.str);
		return 0;
	}
	else if(op.equal==1){
		if(strcmp("POISON",op.str)==0)
		{
			if(poisoned==op.num) {
				queue[numQue]=routines[getRoutine("POISON")];
				numQue++;
				return 0;
			}
			else return -1;
		}
		else if(strcmp("WOUND",op.str)==0) 
		{
			if(wounded==op.num) {
				queue[numQue]=routines[getRoutine("WOUND")];
				numQue++;
				return 0;
			}
			else return -1;
		}
		else if(strcmp("POISON_COUNTER",op.str)==0){
			if(poison_counter==op.num) return 0;
			else return -1;
		}
		else if(strcmp("WOUND_COUNTER",op.str)==0){
			if(wound_counter==op.num) return 0;
			else return -1;
		}
		else return -1;
	}
	else if(op.tell==1){
		printf("%s\n",op.str);
		return 0;
	}
	else if(op.setg==1){
		if(strcmp("POISON",op.str)==0){
			poisoned=op.num;
		}
		else if(strcmp("WOUND",op.str)==0){
			wounded=op.num;
		}
		else if(strcmp("POISON_COUNTER",op.str)==0){
			poison_counter=op.num;
		}
		else if(strcmp("WOUND_COUNTER",op.str)==0){
			wound_counter=op.num;
		}
		return 0;
	}
}
//Loops through all the statements array and does them
void doStatements(struct statement *stmts, int numStmts){
	int i,j;
	for(i=0;i<numStmts;i++){
		if(stmts[i].condstmt.numOperations==0) doOperation(stmts[i].operstmt);  //if not a conditional statement
		else{
			struct cond c = stmts[i].condstmt;
			if(doOperation(c.condition)==0){	//Check the conditional statement's predicate is true
				for(j=0;j<c.numOperations;j++){		//Does all of it's clauses if it is
					doOperation(c.operations[j]);
				}
			}
		}
	}
}
/*Finds a object in the objects array 
@return the position*/
int getObject(char* name){
	for(x=0; x<numObjects; x++){
		if(strcmp(objects[x].name,name)==0){
			return x;
		}
	}
	return -1;
}

/*Finds a room in the rooms array 
@return the position*/
int getRoom(char* name){
	for(x=0; x<numRooms; x++){
		if(strcmp(rooms[x].name,name)==0){
			return x;
		}
	}
	return -1;
}

/*Finds a routine in the routines array 
@return the position*/
int getRoutine(char* name){
	for(x=0; x<numRoutines; x++){
		if(strcmp(routines[x].name,name)==0){
			return x;
		}
	}
	return -1;
}

%}
%token LB RB LP RP TITLE AUTHOR RELEASE  ROOM LOC DESC LDESC NORTH EAST SOUTH WEST TO STUFF ACTION 
%token OBJECT VERB EQUAL QUOTE COMMA SET SETG ROUTINE COND TELL EAT ADJECTIVE UNDERSTAND
%token UP DOWN LOOK INVENTORY DROP TAKE REMOVE WORD STRING NUM MATH STORYDESC STOMP THROW BURNINATE
%union{
	char* string;
	int val;
}

%type<string> WORD STRING  
%type<val> NUM

%error-verbose	//For debugging

%%

input:
	|input instruction 	
	|input command;				
	;

instruction:
	LB SET WORD NUM RB
	{
		tempObject = objects[getObject($3)];
		rooms[getRoom(tempObject.loc)].numObjs=$4;
	}			
	|
	LB TITLE STRING RB
	{
		title = $3;
	}
	|
	LB AUTHOR STRING RB
	{
		author = $3;
	}
	|
	LB RELEASE STRING RB
	{
		release = $3;
	}
	|
	LB STORYDESC STRING RB
	{
		sdesc = $3;
	}
	|
	LB ROOM WORD rProperties RB
	{
		tempRoom.name = $3;
		rooms[numRooms]=tempRoom;
		if(numRooms==0)current=tempRoom;  //The current room is set to the first room created by default
		numRooms++;
		tempRoom = emptyRoom;
	}
	|
	LB OBJECT WORD oProperties RB
	{
		tempObject.name = $3;
		objects[numObjects]=tempObject;
		numObjects++;
		rooms[getRoom(tempObject.loc)].obj=tempObject;
		rooms[getRoom(tempObject.loc)].numObjs=1;
		tempObject = emptyO;
	}
	|
	LB ROUTINE WORD LP RP operations RB
	{
		tempRoutine.name = $3;
		for(x=0;x<numStmt;x++,tempRoutine.numStmts++){	
			tempRoutine.stmts[x]=stmts[x];
		}
		routines[numRoutines]=tempRoutine;
		numRoutines++;
		tempRoutine = emptyR; 
		numOps=0; numStmt=0; //reset the num of operations
	}
	|
	LB UNDERSTAND WORD operations RB
	{
		tempCmd.name = $3;
		for(x=0;x<numStmt;x++,tempCmd.numStmts++){	
			tempCmd.stmts[x]=stmts[x];
		}
		cmds[numCmd]=tempCmd;
		numCmd++;
		numOps=0; numStmt=0;
		tempCmd=emptyCmd; 
	}
	;

operations:
	|operations operation
	{
		if(numOps>0){
			tempStmt.operstmt=ops[0];
			stmts[numStmt]=tempStmt;
			numStmt++;
		}
		else{
			stmts[numStmt]=tempStmt;
			numStmt++;
		}
	};

operation:
	LB COND LP operations RP RB
	{
		int s = tempRoutine.numStmts;
		for(x=0;x<numOps;x++){
			tempCond.operations[x]=ops[x];
		}
		numOps=0; 
		tempStmt.condstmt = tempCond;
		tempCond = emptyC;
	}
	|
	LB VERB COMMA WORD RB
	{
		
		tempOperation.verb=1;
		tempOperation.str=$4;
		tempCond.condition = tempOperation;
		tempOperation = emptyOp;
	}
	|
	LB EQUAL COMMA WORD NUM RB
	{
		tempOperation.equal=1;
		tempOperation.str=$4;
		tempOperation.num = $5;
		tempCond.condition = tempOperation;
		tempOperation = emptyOp;
	}
	|
	LB REMOVE COMMA WORD RB
	{
		tempOperation.remove=1;
		tempOperation.str=$4;
		ops[numOps]=tempOperation;
		numOps++;
		tempOperation = emptyOp;
	}
	|
	LB TELL STRING RB
	{
		tempOperation.tell=1;
		tempOperation.str=$3;
		ops[numOps]=tempOperation;
		numOps++;
		tempOperation = emptyOp;
	}
	|
	LB SETG WORD NUM RB
	{
		tempOperation.setg=1;
		tempOperation.str=$3;
		tempOperation.num=$4;
		ops[numOps]=tempOperation;
		numOps++;
		tempOperation = emptyOp;
	}
	;

rProperties:
	|rProperties rProperty
	;

rProperty:
	LP LOC WORD RP
	{
		tempRoom.loc = $3;
	}
	|
	LP DESC STRING RP
	{
		tempRoom.desc = $3;
	}
	|
	LP LDESC STRING RP
	{
		tempRoom.ldesc = $3;
	}
	|
	exit
	;

oProperties:
	|oProperties oProperty
	;

oProperty:
	LP LOC WORD RP
	{
		tempObject.loc = $3;
	}
	|
	LP DESC STRING RP
	{
		tempObject.desc = $3;
	}
	|
	LP LDESC STRING RP
	{
		tempObject.ldesc = $3;
	}
	|
	LP ADJECTIVE WORD RP
	{
		tempObject.adj = $3;
	}
	|
	LP ACTION WORD RP
	{
		tempObject.action = $3;
	}
	;


exit:
	LP NORTH TO WORD RP
	{
		tempRoom.north = $4;
	}
	|
	LP EAST TO WORD RP
	{
		tempRoom.east = $4;
	}	
	|
	LP SOUTH TO WORD RP
	{
		tempRoom.south = $4;
	}
	|
	LP WEST TO WORD RP
	{
		tempRoom.west = $4;
	}
	|
	LP UP TO WORD RP
	{
		tempRoom.up = $4;
	}
	|
	LP DOWN TO WORD RP
	{
		tempRoom.down = $4;
	}
	;

command:
	NORTH
	{
		if(current.north!='\0'){
			current = rooms[getRoom(current.north)];
			printf("%s\n%s\n",current.desc,current.ldesc);
		}
		else printf("Can't go north.\n");
		
	}
	|
	SOUTH
	{
		if(current.south!='\0'){
			current = rooms[getRoom(current.south)];
			printf("%s\n%s\n",current.desc,current.ldesc);
		}
		else printf("Can't go south.\n");
	}
	|
	EAST
	{
		if(current.east!='\0'){
			current = rooms[getRoom(current.east)];
			printf("%s\n%s\n",current.desc,current.ldesc);
		}
		else printf("Can't go east.\n");
	}
	|
	WEST
	{
		if(current.west!='\0'){
			current = rooms[getRoom(current.west)];
			printf("%s\n%s\n",current.desc,current.ldesc);
		}
		else printf("Can't go west.\n");
	}
	|
	UP
	{
		if(current.up!='\0'){
			current = rooms[getRoom(current.up)];
			printf("%s\n%s\n",current.desc,current.ldesc);
		}
		else printf("Can't go up.\n");
	}
	|
	DOWN
	{
		if(current.down!='\0'){
			current = rooms[getRoom(current.down)];
			printf("%s\n%s\n",current.desc,current.ldesc);
		}
		else printf("Can't go down.\n");
	}
	|
	DROP WORD
	{
		currCmd="DROP";	//Used with the verb operation
		allUpper($2); //Name of the object must be in uppercase to find it in the inventory 
		int pos = inInv($2);
		if(pos>=0){
			inventory[pos].num--;
			deleteItemInv($2);
			allLower($2);
			printf("You dropped a %s\n",$2);
		}
		else { 
			allLower($2);
			printf("You are not carrying a %s\n",$2);	
		}
		
	}
	|
	TAKE WORD
	{
		currCmd="TAKE";
		allUpper($2);	
		int n = getObject($2);	//get the pos of the object
		if(n>=0){
			tempObject = objects[n];
			tempRoom = rooms[getRoom(tempObject.loc)];
			if(strcmp(current.name,tempRoom.name)==0){
				struct map m;
				int pos = inInv($2);
				if(pos>=0) inventory[pos].num++; //If an object is in the inventory increment number of it
				else{				//Else create a new map and add it to the inventory
					m.obj=tempObject;
					m.num=1;
					inventory[numInv]=m;
					numInv++;
		
				}
				rooms[getRoom(tempObject.loc)].numObjs--;
				current = rooms[getRoom(tempObject.loc)];
				tempObject = emptyO;
				allLower($2);
				printf("You took a %s\n",$2);
				allUpper($2);
			}
		}
		else {
			allLower($2);
			allLower(current.name);
			printf("There are no %s in %s\n",$2,current.name);
			allUpper(current.name);	
		}
	}
	|
	LOOK
	{
		if(current.numObjs>0){
			if(current.obj.ldesc!='\0') printf("You see %d %ss. %s\n",current.numObjs,current.obj.desc,current.obj.ldesc);
			else printf("You see %d %ss\n",current.numObjs,current.obj.desc);
		}
		else printf("%s\n",current.ldesc);
	}
	|
	INVENTORY
	{
		if(numInv<=0) printf("Empty\n");
		else{
			for(x=0;x<numInv;x++){
				char *s = inventory[x].obj.name;
				allLower(s);
				printf("%d %s\n",inventory[x].num,s);
				allUpper(s);
			}
		}
	}
	|
	EAT WORD
	{
		currCmd="EAT";
		allUpper($2);
		int pos = getObject($2);
		if(pos>=0){
			tempObject = objects[pos];
			int n = inInv($2);
			if(n!=-1){
				if (tempObject.action !='\0'){
					tempRoutine = routines[getRoutine(tempObject.action)];
					doStatements(tempRoutine.stmts,tempRoutine.numStmts);
				}
				allLower($2);
				if(tempObject.adj !='\0') printf("You eat the %s %s.\n",tempObject.adj,$2);
				else printf("You eat the %s.\n",$2);
				allUpper($2);
				inventory[n].num--;
				deleteItemInv($2);
			}
			else {
			allLower($2);
			printf("You don't have any %s to eat\n",$2);
			}
		}
		
	}
	|
	WORD 
	{
		//Search the commands array and if found does all the statements
		allUpper($1);
		int found = 0;
		for(x=0;x<numCmd;x++){
			if(strcmp(cmds[x].name,$1)==0){
				found = 1;
				doStatements(cmds[x].stmts,cmds[x].numStmts);
			}
		}
		if(found==0) printf("%s is not a recognaziable command\n",$1);
	}
	;

%%
int main(int argc, char *argv[])
{
	if(argc < 2){
		printf("Invalid number of arguments");
		exit(-1);
	}
	FILE *inFile;
	inFile = fopen(argv[1],"r");
	if(!inFile){
		printf("Error opening file.\n");
		exit(-1);
	}
	yyin = inFile;
	yyparse();

	return(0);
}


