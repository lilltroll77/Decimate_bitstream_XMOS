# 64x decimation of a 20 MHz bit-stream for XMOS XCORE-200
Efficient asm optimized 64x decimation of a 1 bit stream for XMOS XCORE-200.
Intended for use with 20 MHz 1-bit Sigma-Delta ADC.

512 taps FIR filter can run on a 71 MHz thread with a 19.2 MHz bitstream or a 704 taps FIR filter on a 100 MHz thread.
If the thread was to late to fetch portdata, an exeption is raised.

This example runs on the XMOS XCORE-200 explorer kit.
Connect port 1N with port 1M with a jumper on tile 0.

The latency between when the last bit on the port is read until the FIR calculation has finished is only 3 instruction cycles. 
On the 4:th cycle the result is sent on a streaming channel.
