# NTUST-Compiler-Simple-Scala
 NTUST 108-2 Compiler Course Project

## Project 3 - Code Generation
```
$ make all

# or

$ lex lex.l
$ yacc -d yacc.y -d
$ g++ -o parser y.tab.c symbolTable.cpp -ll -ly -std=c++11
```
+ if you haven't javaa Assembler:  `$ cd javaa/ && make javaa`

### `lex.l` 修改記錄
1. 修正 `lex.l:158`: ~~`getc(yyin)`~~ → `yyinput()`
1. 修正 `lex.l:159`: ~~`ungetc(c, yyin)`~~ → `unput(c)`

### `symbolTable.h` 修改記錄
1. class `ident` 新增成員 `std::string accessBC`
1. class `ident` 新增成員 `std::string storeBC`
1. class `symbolTable` 新增成員 `int localValIndex`
1. class `symbolTable` 新增成員 `bool returnCheck`

### `yacc.y` 修改記錄
1. 修正 proj2 錯誤（少宣告關鍵字 `float`，`%` function type check typo）
1. 刪除不需要的變數 `legalMethod`
1. 新增 Code Generation 部分以符合 proj3 要求

## Project 2 - yacc parser
```
make all

# or

lex lex.l
yacc -d yacc.y -d
g++ -o parser y.tab.c symbolTable.cpp -ll -ly -std=c++11
```
### `lex.l` 修改記錄
1. 修改 symbolTable 實作方式，並獨立程式碼到 `symbolTable.h/.cpp`
1. 引入 `y.tab.h`
1. 若沒 define `OUTPUT` 不會像 project1 輸出 token
1. 將需要的資料數值存到 `yylval`
1. 第三部分的 c code 移除
1. 新增判斷 `<-`, `read`, `%`, `CHARACTER`

### `parser` 使用方式
    ./parser <filename>

## Project 1 - lex scanner
```
lex lex.l
cc -o scanner -O lex.yy.c -ll
```
掃描程式碼中的 token 並輸出，程式最後輸出 symbol table。
### `scanner` 使用方式
    ./scanner < [input stream]