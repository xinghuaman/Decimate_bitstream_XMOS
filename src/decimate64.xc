/*
 * decimate64.xc
 *
 *  Created on: 18 dec 2020
 *      Author: micke
 */

#include "xs1.h"
#include "xclib.h"
#include "print.h"
#include "calcLUT.h"
#include "defines.h"



void decimate64asm(streaming chanend c , in buffered port:32 p , int* h_ptr , int bitpattern[2*FIFO_INT]);

#pragma unsafe arrays
void decimate64(streaming chanend c , in buffered port:32 p){
    int h[BLOCKS][SIZE]; //sp
    int bitpattern[2*FIFO_INT]={0};
    //set_core_high_priority_on();
#ifndef SIMULATE
    int max=calcLUT(h);
    printstr("Absolute headroom: ");
    int headroom= 0x7FFFFFFF-max;
    printintln(headroom);
    if(headroom==0){
        printstrln("ERROR: LUT has clipped");
        return;
    }
#endif
    decimate64asm(c , p , h[BLOCKS-1] , bitpattern);
}

    
