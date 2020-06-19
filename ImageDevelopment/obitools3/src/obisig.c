/****************************************************************************
 *  Functions for signal catching and handling                              *
 ****************************************************************************/

/**
 * @file obisig.c
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date September 2019
 * @brief Functions for signal catching and handling.
 */

#include "obidebug.h"
#include "obierrno.h"
#include "obisig.h"

#include <stdbool.h>
#include <signal.h>


#define DEBUG_LEVEL 0	// TODO has to be defined somewhere else (cython compil flag?)


bool volatile keep_running = true;


void sig_handler(int signum)
{
	obi_set_errno(OBI_SIGNAL_CAUGHT);
	obidebug(1, "\nCaught signal: %s\n", strsignal(signum));
	keep_running = false;
}
