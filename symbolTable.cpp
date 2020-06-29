#include "symbolTable.h"

using namespace std;


ident::ident() {
    this->name = "";
    this->type = NON_TYPE;
}

ident::ident(std:: string name, int type) {
    this->name = name;
    this->type = type;
}

ident::~ident() {
    this->args.clear();
}

/* Insert Method Parameter data type */
void ident::addParam(int type) {
    this->args.push_back(type);
}

symbolTable::symbolTable() {
    this->scopeName = "";
    this->fatherTable = NULL;
    this->returnType = NON_TYPE;
    this->localValIndex = 0;
    this->returnCheck = false;
}

symbolTable::symbolTable(std::string scopeName, symbolTable* fatherTable) {
    this->scopeName = scopeName;
    this->fatherTable = fatherTable;
    this->returnType = NON_TYPE;
    this->localValIndex = 0;
    this->returnCheck = false;
}

symbolTable::~symbolTable() {
    this->idents.clear();
}

/* insert identifier in symbol table */
void symbolTable::insert(string s, int type) {
    map<string, ident*>::iterator iter;

    iter = this->idents.find(s);

    if (iter == this->idents.end()) {
        this->idents[s]= new ident(s, type);
    }
}

/* lookup identifier is in symbol table or outer scope table then return */
ident* symbolTable::lookup (string s, bool searchFather) {
    map<string, ident*>::iterator iter;
    symbolTable* cur_table = this;
    while (cur_table != NULL) {
        iter = cur_table->idents.find(s);

        if (iter != cur_table->idents.end()) {
            return cur_table->idents[s];
        }

        if (searchFather) {
            cur_table = cur_table->fatherTable;
        }
        else {
            cur_table = NULL;
        }
    }
	
    // if not found
	return NULL;
}

/* create child symbol table and set father table is self */
symbolTable* symbolTable::createChild(std::string s) {
    symbolTable* tempTable;
    tempTable = new symbolTable(s, this);
    return tempTable;
}

