#include "ecoPCR.h"
#include <stdio.h>
#include <stdlib.h>

/*
 * print the message given as argument and exit the program
 * @param error		error number	
 * @param message 	the text explaining what's going on
 * @param filename	the file source where the program failed
 * @param linenumber	the line where it has failed
 * filename and linenumber are written at pre-processing 
 * time by a macro
 */
void ecoError(int32_t error,
              const char* message,
              const char * filename,
              int linenumber)
{
	fprintf(stderr,"Error %d in file %s line %d : %s\n",
	               error,
	               filename,
	               linenumber,
	               message);
	
	abort();
}
