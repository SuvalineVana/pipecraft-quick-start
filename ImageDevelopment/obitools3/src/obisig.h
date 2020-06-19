/****************************************************************************
 * Header file for obisig                                                   *
 ****************************************************************************/

/**
 * @file obisig.h
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 * @date September 2019
 * @brief Header file for signal catching and handling.
 */


#ifndef OBISIG_H_
#define OBISIG_H_

#include <stdint.h>
#include <signal.h>
#include <stdbool.h>


/**
 * @brief Signal handling.
 *
 * @since September 2019
 * @author Celine Mercier (celine.mercier@metabarcoding.org)
 *
 */
bool volatile keep_running;
void sig_handler(int signum);


#endif /* OBISIG_H_ */
