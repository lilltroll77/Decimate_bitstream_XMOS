# Realtime 64x decimation with a 768 tap anti-alias FIR-filter of a 20 MHz bit-stream for XMOS XCORE-200 using one thread
Efficient asm optimized 64x decimation of a 1 bit stream for XMOS XCORE-200.
Intended for use with 20 MHz 1-bit Sigma-Delta ADC.

512 taps FIR anti-alias filter can run on a 71 MHz thread with a 19.2 MHz bitstream or a 768 taps FIR filter on a 100 MHz thread.
If the thread was to late to fetch portdata, an exeption is raised.

The FIR filter does not need to be symetric, thus minimum phase filters is possible.

This example runs on the XMOS XCORE-200 explorer kit.
Connect port 1N with port 1M with a jumper on tile 0.

The latency between when the last bit on the port is read until the FIR calculation has finished is only 3 thread clock cycles. 
On the 4:th cycle the result is sent on a streaming channel.

Realtime FIR calculation is done with a lookup table. This way 8 bits of inputdata can be convoltued and accumulated with 8 taps of the FIR filter in just 3 thread clock cycles.
