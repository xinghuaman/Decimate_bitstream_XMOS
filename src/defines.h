/*
 * defines.h
 *
 *  Created on: 20 dec 2020
 *      Author: micke
 */

#ifndef DEFINES_H_
#define DEFINES_H_

#define FIRLEN (512+192)  // must be an multiple of 64 (int64)
#define WORD_SIZE 8
#define SIZE (1<<WORD_SIZE) //Number of combinations
#define BLOCKS (FIRLEN/WORD_SIZE)
#define FIFO_INT (FIRLEN/32) //Size of FIFO in int32
#define CT 6

#if BLOCKS > 100
#error This implementaion only handles BLOCKS <= 100
#endif

#endif /* DEFINES_H_ */
