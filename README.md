# 64x decimation of a 1 bit stream for XMOS XCORE-200
Efficient asm optimized 64x decimation of a 1 bit stream for XMOS XCORE-200.
Intended for use with 20 MHz 1-bit Sigma-Delta ADC.

512 taps FIR filter can run at 500/7 MHz thread frequency. 
If the thread was to late to fetch portdata, an exeption is raised.

This example runs on the XMOS XCORE-200 explorer kit.
Connect port 1N with port 1M with a jumper on tile 0.
