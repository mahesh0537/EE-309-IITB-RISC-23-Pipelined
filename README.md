# EE-309-IITB-RISC-23-Pipelined

This repo contains the VHDL code and ISA for a 6-stage pipelined processor, *IITB-RISC-23*. *IITB-RISC-23* is a 16-bit computer with 8 registers, and is based on the Little Computer Architecture and has been developed for teaching. Hazard mitigation techniques have been included, with data forwarding capabilities so as to improve the performance.

The registers are named R0 to R7. R0 is always the Program Counter, being capable of fetching 2 bytes of data. The architecture uses a condition code register comprising of 2 bits - the Carry Flag (CF) and the Zero Flag (ZF). The 6 stages in the pipeline are:
1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Register Read (RR)
4. Executer (EX)
5. Memory Access (MA)
6. Write Back (WB)

The ISA consists of a total of 14 instructions, which have been divided into 3 formats - R, I and J.

## Overview of each VHDL file

1. alu.vhd
This consists of 2 entities - `ALU` and `ALU_wrapper`. The job of the ALU, like always, is to perform all the arithmetic and logical functions that might be needed of the CPU. The `ALU_Wrapper` takes care of the other signals that are relevant to the ALU, like the CF and ZF flags, value of the `compliment` and `condition` signals. It reads and modifies them, and allows the implementation of different instrcuctions like `ada`, `adc` and `adz` without difficulty.
2. branch.vhd
The 2 entities in this file are - `conditionalBranchHandler` and `unconditionalBranchHandler`, and the role of each entity is pretty clear from their names. `conditionalBranchHandler` handles branching in case of instructions like  `beq` and `blt`. Whereas the `unconditionalBranchHandler` handles branching in the case of `jal` and `jlr`.
3. branch_hazard.vhd
Has a single entity, which tells if the predicted branch and the branch actually take are the same or not, thereby detecting hazards.
4. data_hazard.vhd
Consists of 2 entities - `DataHazardDetector` and `dataForwarder`. `DataHazardDetector` is implemented as has been taught in the course, with arithmetic hazards being taken care of by data forwarding. The immediate dependency data loading hazards are handled by pausing the pipeline upto the execution of the load instruction. `dataForwarder` just implements the data forwarding algorithm. 
5. execution.vhd
