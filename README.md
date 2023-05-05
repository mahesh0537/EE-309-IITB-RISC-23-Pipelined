# EE309 Microprocessors Project
This repo contains the VHDL code and ISA for a 6-stage pipelined processor, *IITB-RISC-23*. *IITB-RISC-23* is a 16-bit computer with 8 registers, and is based on the *Little Computer Architecture** and has been developed for teaching. Hazard mitigation techniques have been included, with data forwarding capabilities so as to improve the performance.

The registers are named R0 to R7. R0 is always the Program Counter, being capable of fetching 2 bytes of data. The architecture uses a condition code register comprising of 2 bits - the Carry Flag (CF) and the Zero Flag (ZF). The 6 stages in the pipeline are:
1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Register Read (RR)
4. Executer (EX)
5. Memory Access (MA)
6. Write Back (WB)

The ISA consists of a total of 14 instructions, which have been divided into 3 formats - R, I and J.

*`LM` and `SM` instructions have been microcoded i.e. they have been broken down into smaller instructions each of which takes one cycle to complete. This results in the `LM` and `SM` instructions needing a maximum of 8 cycles to complete.

## Algorithms implemented

### Data hazard handling
The same algorithm as has been taught in the course EE309 has been implemented here. We utilize data forwarding to deal with all hazards but the one caused by immediate dependency load instructions. In the case of an immediate dependency load instruction, the pipeline is stalled for one cycle - the load instruction is allowed to move ahead into the pipeline, while the previous instruction stays stationary for one cycle. 

### Branch prediction
A 2-bit saturation counter is used as the branch prediction algorithm here. The advantage of the two-bit counter scheme over a one-bit scheme is that a conditional jump has to deviate twice from what it has done most in the past before the prediction changes.
The FSM diagram is given below:
![alt text](https://upload.wikimedia.org/wikipedia/commons/c/c8/Branch_prediction_2bit_saturating_counter-dia.svg)
As can be seen, the FSM has 4 states:
  1. Strongly not taken
  2. Weakly not taken
  3. Weakly taken
  4. Strongly taken

## Overview of each VHDL file

1. **alu.vhd**  
This consists of 2 entities - `ALU` and `ALU_wrapper`. The job of the ALU, like always, is to perform all the arithmetic and logical functions that might be needed of the CPU. The `ALU_Wrapper` takes care of the other signals that are relevant to the ALU, like the CF and ZF flags, value of the `compliment` and `condition` signals. It reads and modifies them, and allows the implementation of different instrcuctions like `ada`, `adc` and `adz` without difficulty.

2. **branch.vhd**  
The 2 entities in this file are - `conditionalBranchHandler` and `unconditionalBranchHandler`, and the role of each entity is pretty clear from their names. `conditionalBranchHandler` handles branching in case of instructions like  `beq` and `blt`. Whereas the `unconditionalBranchHandler` handles branching in the case of `jal` and `jlr`.

#3. **branch_hazard.vhd**
Has a single entity, which tells if the predicted branch and the branch actually take are the same or not, thereby detecting hazards.

#4. **branch_predictor.vhd**
Contains 3 entities - `branchPredictorALU`, `branchComparator` and `branchPredictor`. The `branchPredictorALU` is a specific ALU with adders and shifters for pre-calculating the new program counter values. `branchComparator` is responsible for finding the history of the current branch, if at all it exists, and allow the updation of its history. `branchPredictor` performs the branch prediction algorithm.

#5. **data_hazard.vhd**
Consists of 2 entities - `DataHazardDetector` and `dataForwarder`. `DataHazardDetector` is implemented as has been taught in the course, with arithmetic hazards being taken care of by data forwarding. The immediate dependency data loading hazards are handled by pausing the pipeline upto the execution of the load instruction. `dataForwarder` just implements the data forwarding algorithm. 

#6. **execution.vhd**
There is only 1 large entity here named `execStage`. It handles the execution of all the instructions, based on the instruction type. Corresponds to the 4th stage of the pipeline.

#7. **flagReg.vhd**
Singular entity named `flagReg` which handles the 1 bit registers storing CFlag and ZFlag.

#8. **instructionFetch.vhd**
Consists of 1 entity named `instructionFetch`. Responsible for obtaining the next instruction to be executed from the memory. Corresponds to the 1st stage of the pipeline.

#9. **instructionMem.vhd**
Singular entity named `instructionMemory` which stores all the instructions into a separate memory. This is being done since we are using the Harvard architecture of a computer.

#10. **instructionMemSkeleton.vhd**
Template file used to generate instructionMem.vhd using the python script bootloader.py. This file is not used in the final compilation.

#11. **instruction_decode.vhd**
The only entity in this file is named `instructionDecoder`. It decodes all the instructions inputted into the pipeline and converts them into signals which are propagated in the pipeline. Corresponds to the 2nd stage of the pipeline.

#12. **loadStoreMultipleHandler.vhd**
Consists of `registerFileHandler`, `priorityEncoder`, `LwSwHandler`

#11. **load_store.vhd**
Consists of 1 entity called `loadStoreHandler` which handles the load and store instructions `LW` and `SW` respectively in the ISA.

#12. **main.vhd**
Consists of one entity - `pipelineDataPath` which creates all the pipeline registers. The rest of the code initializes and connects all the component blocks, providing us with a working processor. 

#13. **memory.vhdl**
Singular entity named `memory` which implements a 64 kB memory. The memory is byte addressable.

#14. **register.vhd**
Singular entity named `NBitRegister`. As the name suggests, allows the implementation of a N-bit register. 

#15. **sign_extenders.vhd**
Singular entity named `signExtender`. Performs sign extension for immediate values.

#16. **writeBack.vhd**
Single entity named `writeBack` which is responsible for generating the register write back signals for the processor. 
