# CAD-for-VLSI
## Problem Statement:
Design, implement and test a **Pipelined 64 bit signed Integer Multiply and Accumulate (IMAC)** unit using Bluespec SystemVerilog

## Introduction
The IMAc unit needs to perform 64-bit * 64-bit signed multiplication, and subsequently, addition. This was achieved by using an array multiplier followed by an adder. A two-stage pipeline was implemented: a pipelining register was placed within the multiplier so that the combinational delays of the prior portion of the multiplier and the remaining portion, along with the adder, would be comparable.

The IMAc module is available in `imac.bsv`.

## The IMAc Module
The IMAc module offers the `Ifc_IMAC` interface, which contains the following methods:
- `method Action start(Bit#(n) inpA, Bit#(m) inpB);` : This may be used to supply, at any clock cycle, inputs to the module
- `method Bit#(TAdd#(n,m)) result;` : This is used to obtain, at any clock cycle, the final valid result computed and stored in the module
- `method Action rst;` : This is used to reset, at any clock cycle, all the registers in the module to their default values
- `method Bit#(1) isRdy;` : This is used to check whether the module has completely performed a computation and has a valid result to be read

The latency of the module is 2 clock cycles. The module may be supplied with new values at every clock cycle, and will take two cycles to compute the result corresponding to these inputs. After the module has been started once, if no input is supplied in a subsequent cycle, the module will offer the result of its last computation as the result corresponding to this cycle. In order to reset the module and start afresh, the method `rst` has to be called explicitly.

## Multiplier
A parameterized n-bit * m-bit array multiplier was implemented with carry-saving to reduce the critical path delay. The multiplier was further parameterized by the `SIGN` option: if `SIGN` is defined as 1, it would synthesize a signed multiplier, whereas if `SIGN` is set to zero, it wold synthesize an unsigned multiplier. The boolean algebra for performing n-bit * m-bit signed and unsigned multiplications was worked out in order to create this design.

The array multiplier contains two distinct portions:
- The summation of partial products in the array to generate an m-bit array sum
- The vector merge stage, where this is added with the final partial products using a fast m-bit adder

## Accumulate
After computing the result of the multiplication, it has to be added with the present value stored in the module's output register. Hence, the accumulate stage would consist of an m+n bit adder.

## Pipelining
A pipelining register is placed after the array sum stage, splitting the IMAc into two parts:
- The array sum
- The vector merge stage followed by the accumulating adder

Calling the start method supplies the input values to the first stage of the pipeline (contained in the rule `compute_Mult`) through DWires. That is, the input values are supplied to the first stage in the same clock cycle that the `start` method is called in. In cycles where the method is not called, a default value of `0` is supplied.

Similarly, the pipelining register and result register are updated only in clock cycles where the method is called. This is achieved by using a `wr_state` DWire that updates a `state` register with the value `Compute_Mult` whenever the method is called, and a default `Idle` whenever it is not.

The result register `accum` is declared as a `Maybe` type. This is to ensure that the module does not supply garbage values when its result is read. This is ensured by making the value of `accum` valid only when the result of a computation is stored in it, and invalid when the module is reset.

## Testing
The module's functionality was tested using the Bluespec testbench `imac_tb.bsv`. The steps for this build are found in the `Makefile` target `test`. It was subsequently synthesized using YoSys. The synthesis command is found in the target `synthesize`. 