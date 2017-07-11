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

