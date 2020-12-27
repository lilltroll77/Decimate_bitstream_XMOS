/*
 * calcLUT.xc
 *
 *  Created on: 20 dec 2020
 *      Author: micke
 */

#include <xs1.h>
#include <xclib.h>
#include "decimate.h"
#include "FIRcoef.h"
#include <stdlib.h>

int calcLUT(int h[BLOCKS][SIZE]){
    int max=0;
    for(int block=0; block<BLOCKS ; block++){
        int pos = block*WORD_SIZE;
        for(int i=0; i< SIZE ; i++){
            int sum=0;
            for(int k=0; k<WORD_SIZE ; k++){
                if((i>>k)&1 )
                    sum += hFIR[k+pos];
            }
            h[block][byterev(bitrev(i))] = sum;
            if(abs(sum) > max)
                max=abs(sum);
        }
    }
    return max;
}
