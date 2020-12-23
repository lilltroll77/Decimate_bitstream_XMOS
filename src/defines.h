/*
 * defines.h
 *
 *  Created on: 20 dec 2020
 *      Author: micke
 */

#ifndef DEFINES_H_
#define DEFINES_H_

#define FIRLEN 512
#define WORD_SIZE 8
#define SIZE (1<<WORD_SIZE)
#define BLOCKS (FIRLEN/WORD_SIZE)
#define FIFO_INT (FIRLEN/32)

#define CT 6

#endif /* DEFINES_H_ */
