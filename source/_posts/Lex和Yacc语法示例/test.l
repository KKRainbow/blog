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
