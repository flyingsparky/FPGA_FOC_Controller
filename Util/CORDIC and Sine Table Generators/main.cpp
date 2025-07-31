#include <iostream>
#include "cordiclib.h"
#include "sintable.h"

using namespace std;

int main() {
	FILE* fp = fopen("output.txt", "w");
	char fname[8] = "bruh";
	const char hexname[8] = "output";
	//cordic_angles(fp, 8, 16);
	sintable(fp,fname,hexname,16,16,1,0,1);
	return 0;
}