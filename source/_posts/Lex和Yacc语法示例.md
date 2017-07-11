---
title: Lex和Yacc语法示例
date: 2017-07-11 19:34:54
tags: 
	- bison 
	- flex
categories:
	- 工具使用
---

为了方便以后用到的时候能快速想起lex和yacc的语法和编译过程，在此把之前写的一些东西记录下来。

<!--more-->


# 要解析的文件


{% asset_link barrelrpc.if "Interface File" %}

```plain
/*
fkdlsajlkfjldska
fdlksajlkfsdjla
flkdsjalkfdsj
typedef struct {
		int32 a;
		int32 b;
		int8 c;
	} mystruct;
, out mystruct st
*/
interface barrelrpc "Example rpc interface" {

	rpc myrpc(in int32 qqq, out String s[2048]);
};

```

# Lex文件示例

{% asset_link test.l "词法文件" %}

```lex
%{/* -*- C++ -*- */
#include <string>
#include <cmath>
#include "test.tab.hh"

static yy::location loc;

#define YY_DECL yy::FlounderFileParser::symbol_type yylex()
%}

%option noyywrap nounput batch nodebug noinput

identy [a-zA-Z][a-zA-Z0-9_]*
int [0-9]+
hex 0x[0-9a-fA-F]+
blank [ \t]
string \"([^"\n]|\\\")+\"
typedef typedef

%{
#define YY_USER_ACTION loc.columns(yyleng);
%}


%%
%{
	loc.step();
%}
{blank}+ loc.step();
[\n]+ loc.lines(yyleng);loc.step();

"/*"([^\*]|(\*)*[^\*/])*"*/" {}

typedef return yy::FlounderFileParser::make_TYPEDEF_KEYWORD(loc);
struct return yy::FlounderFileParser::make_STRUCT_KEYWORD(loc);
enum return yy::FlounderFileParser::make_ENUM_KEYWORD(loc);
rpc return yy::FlounderFileParser::make_RPC_KEYWORD(loc);
interface return yy::FlounderFileParser::make_INTERFACE_KEYWORD(loc);

"," return yy::FlounderFileParser::make_COMMA(loc);
";" return yy::FlounderFileParser::make_COLON(loc);
"{" return yy::FlounderFileParser::make_LBRACE(loc);
"}" return yy::FlounderFileParser::make_RBRACE(loc);
"(" return yy::FlounderFileParser::make_LPAREN(loc);
")" return yy::FlounderFileParser::make_RPAREN(loc);
"[" return yy::FlounderFileParser::make_LBRACKET(loc);
"]" return yy::FlounderFileParser::make_RBRACKET(loc);

{string} return yy::FlounderFileParser::make_STRING(yytext, loc);
{int} return yy::FlounderFileParser::make_INTEGER(strtol(yytext, NULL, 10), loc);
{identy} return yy::FlounderFileParser::make_IDENTIFIER(yytext, loc);

<<EOF>> return yy::FlounderFileParser::make_END(loc);
%%
```

# yacc文件

{% asset_link test.yy "语法文件" %}

```yacc
%skeleton "lalr1.cc"

%defines
%define parser_class_name {FlounderFileParser}
%define api.value.type variant
%define api.token.constructor
%define parse.trace
%define parse.error verbose

%locations
%initial-action
{
// Initialize the initial location.
//@$.begin.filename = @$.end.filename = &driver.file;
};


%code requires {

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <cstring>
using namespace std;
struct FunctionParam
{
	enum {
	IN, OUT
	} type;
	string typeName;
	string paramName;
	int val;
};

struct FunctionDecl
{
	string name;
	vector<FunctionParam> params;
};

struct TypeDecl
{
	enum {
	ARRAY, ALIAS, STRUCT, ENUM
	}type;
	string name;
	int val;
	string origin;
};

struct FlounderFile
{
	string name;
	string description;
	vector<FunctionDecl> functions;
	map<string, TypeDecl> types;
};


}

%parse-param {FlounderFile& ff}

%token 
	<string> IDENTIFIER "identifier"
	<string> STRING "string"
;
%token
	END 0 "end of file "
	COLON ";"
	LBRACE "{"
	RBRACE "}"
	LPAREN "("
	RPAREN ")"
	LBRACKET "["
	RBRACKET "]"
	INTERFACE_KEYWORD "interface"
	TYPEDEF_KEYWORD "typedef"
	STRUCT_KEYWORD "struct"
	ENUM_KEYWORD "enum"
	RPC_KEYWORD "rpc"
	COMMA ","
;
%token
	<int> INTEGER
;

%type <FunctionParam> param
%type <vector<FunctionParam>> params
%type <FunctionDecl> function
%type <TypeDecl> type
%type <FlounderFile> types_or_functions
%type <string> param_type param_direct

%%
%code {
yy::FlounderFileParser::symbol_type yylex();
};
%start interface;

interface : "interface" IDENTIFIER STRING "{"
			types_or_functions
		  "}" ";" {ff=$5;ff.name = $2;ff.description = $3;}
;

types_or_functions : %empty {}
				| type types_or_functions {$$ = $2; $$.types[$1.name] = $1;}
				| function types_or_functions {$$ = $2; $$.functions.push_back($1);}
;

type : "typedef" "struct" "{" struct_fields "}" param_type ";" {$$.type=TypeDecl::STRUCT;$$.name=$6;}
	| "typedef" param_type IDENTIFIER "[" INTEGER "]" ";"{$$.type=TypeDecl::ARRAY; $$.name=$2; $$.origin=$3; $$.val=$5;}
	| "typedef" "enum" "{" enum_fields "}" param_type ";"{$$.type=TypeDecl::ENUM;$$.name=$6;}
	| "typedef" param_type param_type ";"{$$.type=TypeDecl::ALIAS;$$.name=$2;$$.origin=$3;}
;

struct_fields : %empty
			| struct_fields param_type IDENTIFIER ";"
;

enum_fields : %empty
			| enum_fields "," IDENTIFIER 
			| IDENTIFIER
;

function : "rpc" IDENTIFIER "(" params ")" ";" {
			$$.name = $2;
			$$.params = $4;
		 }
;

params : %empty {}
			| params "," param  {$$.insert($$.begin(), $1.begin(), $1.end()); $$.push_back($3);}
			| param {$$.push_back($1);}
;

param : param_direct param_type IDENTIFIER {
		$$.type = $1 == "in" ? FunctionParam::IN : FunctionParam::OUT;
		$$.typeName = $2;
		$$.paramName = $3;
	  }
		|
		param_direct param_type IDENTIFIER "[" INTEGER "]"{
		$$.type = $1 == "in" ? FunctionParam::IN : FunctionParam::OUT;
		$$.typeName = $2;
		$$.paramName = $3;
		$$.val = $5;
	  }
;

param_type : IDENTIFIER {$$=$1;}
;

param_direct : IDENTIFIER {$$=$1;}
;

%%

void yy::FlounderFileParser::error(const location_type& l, const std::string& m)
{
	return;
}

```

# 编译

```cpp
//main.cpp
#include "test.tab.hh"
#include <stdio.h>
using namespace yy;
using namespace std;

extern FILE* yyin;

static FlounderFile f;

int main(int argc, char* argv[])
{
	FlounderFileParser parser(f);
	yyin = fopen("./barrelrpc.if", "r");
	parser.set_debug_level(true);
	parser.parse();
	return 0;
}

```

```makefile
# Makefile
rpc-compiler: lex.o parser.o main.cpp 
	g++ -std=c++11 -g -lm -o test lex.o parser.o main.cpp

lex.o: test.l parser.o
	flex test.l
	g++ -c -o lex.o lex.yy.c

parser.o: test.yy
	bison test.yy
	g++ -c -o parser.o test.tab.cc

.PHONY: clean run

clean:
	rm *.hh *.cc lex.yy.c *.o
```

# 文档

Bison文档中Calc++一节有非常详细的教程。
- [Bison](https://www.gnu.org/software/bison/manual/bison.pdf)
