typedef enum { typeCon, typeId, typeOpr } typeEnum;

typedef struct {
    double value;                
} conType;

typedef struct {
    int i;                     
} idType;

typedef struct {
    int oper;                   
    int nops;                  
    struct typeNodeStruct *op[1];	
} oprType;

typedef struct typeNodeStruct {
    typeEnum type;            

    union {
        conType con;        
        idType id;          
        oprType opr;        
    };
} typeNode;

extern double sym[26];
