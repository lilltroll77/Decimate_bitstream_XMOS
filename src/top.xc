/*
 * decimate64.xc
 *
 *  Created on: 13 sep 2018
 *      Author: micke
 */


#include "debug_print.h"
#include "print.h"
#include "decimate.h"
#include "calcLUT.h"
#include "xs1.h"
#include "xclib.h"
#include "FIRcoef.h"
#include "xs1.h"

//#define ASM

unsigned burden(unsigned val){
    set_core_high_priority_off();
    unsigned data;
    while(1)
        crc32(data , val , 1);
    return data;
}


//in buffered port:32 p = XS1_PORT_1A;
#define LEN 256


void reference(streaming chanend c){
    int mem[FIRLEN]={0};
    for(int i=0; i<LEN/2 ;i++){
        for(int counter=0 ; counter<64 ; counter ++){
            for(int i=FIRLEN-1; i!=0 ; i--)
                mem[i] = mem[i-1];
            c:> mem[0];
        }
        int acc=0;
        for(int i=0; i<FIRLEN ; i++)
            acc +=mem[i] * hFIR[i];
        c <: acc;//>>FIR_scale; //round after summation
    }
}

#define LIMIT BLOCKS/8



void test(streaming chanend c_fast  , out buffered port:32 p, clock clk){


#define POLY 0xEDB88320
    unsigned data[LEN];
    unsigned ref[LEN/2];
    unsigned fast[LEN/2];
    unsigned crc=1;
    streaming chan c_ref;
#ifndef SIMULATE
    par{
        reference(c_ref);
        {
            int k=0;
            for(int i=0; i<LEN ;){
                crc32(crc , i , POLY);
                data[i++] = crc;
                int r=crc;
                for(int j=0; j<32 ; j++){
                    c_ref <:r&1;
                    r >>=1;
                }
                //crc=0;
                crc32(crc , i , POLY);
                data[i++]=crc;
                r=crc;
                for(int j=0; j<32 ; j++){
                    c_ref <: r&1;
                    r >>=1;
                }


                c_ref :> ref[k++];
            }
        }

    }// end par
#endif
    {
    int i=0;
    p <: data[i++];
    par{
        //Worst case : All other 7 thread runs in core_fast_mode_on
        par(int i=0; i<0 ; i++)
                burden(i); //Allocate
        {
            {
                //Wait for other thread to be ready
                schkct(c_fast , CT);
                start_clock(clk);


                int k=0;
                while(i<LEN-1){
                    p <: data[i++];
                    p <: data[i++];
                    c_fast :> fast[k++];

                }
                p <: data[i];
                c_fast :> fast[k];
            }
            sync(p);
            stop_clock(clk);

#ifndef ASM
            for(int i=0; i<(LEN/2) ;i++){
                debug_printf("%d: fast %d , ref %d" ,i, ref[i] , fast[i]);
                if(ref[i] != fast[i])
                    debug_printf(" !error! \n");
                else
                    debug_printf(" ok \n");
            }
#endif
        }
    }
    }
}

in buffered port:32 p_in=XS1_PORT_1N;
out buffered port:32 p_out=XS1_PORT_1M;
clock clk=XS1_CLKBLK_1;



int main(){
    streaming chan c_fast;
    set_clock_xcore(clk);
    set_clock_div(clk , 13);
    configure_in_port(p_in , clk );
    //Outputs are driven on the next falling edge of the clock
    configure_out_port(p_out , clk , 0 );

    unsigned test_val=0x12345678;
    unsigned val;
    p_out <:test_val;
    start_clock(clk);
    //First bit is the 0 in configure_out_port, should be discarded
    partin(p_in , 1);
    val=partin(p_in,24);
    val=val | partin(p_in,8)<<24;
    sync(p_in);
    stop_clock(clk);
    clearbuf(p_in);
#ifndef ASM
    if(val != test_val){
        printstrln("PORT ERROR!");
        printbinln(test_val);
        printbinln(val);
        return val;
    }
#endif

    par{
        decimate64(  c_fast , p_in);
        test(c_fast , p_out , clk);
    }
    return 0;
}
