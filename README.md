# NTUST-Compiler-Simple-Scala
 NTUST 108-2 Compiler Course Project

## Project 1 - lex scanner
```
lex lex.l
cc -o scanner -O lex.yy.c -ll
```
掃描程式碼中的 token 並輸出，程式最後輸出 symbol table。
### `scanner` 使用方式
    ./scanner < [input stream]

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