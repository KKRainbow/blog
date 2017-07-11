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
