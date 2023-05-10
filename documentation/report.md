<!This is a markdown file, please open it in a editor like vscode which can render markdown.>

# EE309 Microprocessors Project
This repo contains the VHDL code and ISA for a 6-stage pipelined processor, *IITB-RISC-23*. *IITB-RISC-23* is a 16-bit computer with 7 general purpose integer registers, and is based on the *Little Computer Architecture** and has been developed for teaching. Hazard mitigation techniques have been included, with data forwarding capabilities so as to improve the performance.

The registers are named R1 to R7. R0 is the Program Counter. The architecture uses a status register/condition code register comprising of 2 bits - the Carry Flag (CF) and the Zero Flag (ZF). The 6 stages in the pipeline are:
1. Instruction Fetch (IF)
2. Instruction Decode (ID)
3. Register Read (RR)
4. Executer (EX)
5. Memory Access (MA)
6. Write Back (WB)

The ISA consists of a total of 14 instructions, which have been divided into 3 formats - R, I and J.

*`LM` and `SM` instructions are microcoded i.e. they have been broken down into smaller - micro instructions (uops) each of which take one cycle to execute (pipelined). This results in the `LM` and `SM` instructions needing a maximum of 8 cycles to execute.

## Algorithms implemented

### Data hazard handling
The same algorithm as has been taught in the course EE309 has been implemented here. We utilize data forwarding to deal with all hazards. In the case of an immediate dependency load instruction, the pipeline is stalled for one cycle - the load instruction is allowed to move ahead into the pipeline, while the previous instructions stays stationary for one cycle. 

### Branch prediction
A 2-bit saturation counter is used as the branch prediction algorithm here. The advantage of the two-bit counter scheme over a one-bit scheme is that a conditional jump has to deviate twice from what it has done most in the past before the prediction changes.
The FSM diagram is given below:
![alt text](https://upload.wikimedia.org/wikipedia/commons/c/c8/Branch_prediction_2bit_saturating_counter-dia.svg)
As can be seen, the FSM has 4 states:
  1. Strongly not taken
  2. Weakly not taken
  3. Weakly taken
  4. Strongly taken

## Overview* of each VHDL file

1. **alu.vhd**  
This consists of 2 entities - `ALU` and `ALU_wrapper`. The job of the ALU, like always, is to perform all the arithmetic and logical functions that might be needed of the CPU. The `ALU_Wrapper` is responsible to select and forward the correct control signals and operand to the ALU. This allows the implemenation of different instructions like `ada`, `adc`, and `adz` without much difficulty.

2. **branch.vhd**  
The 2 entities in this file are - `conditionalBranchHandler` and `unconditionalBranchHandler`, and the role of each entity is pretty clear from their names. `conditionalBranchHandler` handles branching in case of instructions like  `beq` and `blt`. Whereas the `unconditionalBranchHandler` handles branching in the case of `jal` and `jlr`.

3. **branch_hazard.vhd**  
Has a single entity, which tells if the predicted branch and the branch actually take are the same or not, thereby detecting hazards. The pipeline is flushed in case a branch misprediction occurs.

4. **branch_predictor.vhd**  
Contains 3 entities - `branchPredictorALU`, `branchComparator` and `branchPredictor`. The `branchPredictorALU` is a specific ALU with adders and shifters for pre-calculating the new program counter values. `branchComparator` is used to find the history of the branch, if it exists. It is also used to update the internal state machine of the `branchPredictor`.

5. **data_hazard.vhd**  
Consists of 2 entities - `DataHazardDetector` and `dataForwarder`. `DataHazardDetector` is implemented as has been taught in the course. `dataForwarder` is responsible for selecting the correct data (from the outputs of registerFetch, execute, memory and writeback stages) and forwarding it to the input of the execute stage. Immediate load dependencies are solved by inserting a bubble i.e. stalling the pipeline for 1 cycle.

6. **execution.vhd**  
There is only 1 large entity here named `execStage`. It handles the execution of all the instructions, based on the instruction type. Corresponds to the 4th stage of the pipeline.

7. **flagReg.vhd**  
Singular entity named `flagReg` stores the zero-flag (`ZF`) and carry-flag (`CF`).

8. **instructionFetch.vhd**  
Consists of 1 entity named `instructionFetch`. Responsible for obtaining the next instruction to be executed from the memory. Corresponds to the 1st stage of the pipeline.

9. **instructionMem.vhd**  
Singular entity named `instructionMemory` which stores all the instructions into a separate memory. This is being done since our implementation is a Harvard architecure.

10. **instructionMemSkeleton.vhd**  
Template file used to generate `instructionMem.vhd` using the python script `bootloader.py`. This file is **NOT** used in the final compilation.

11. **instruction_decode.vhd**  
The only entity in this file is named `instructionDecoder`. It decodes all the instructions from the instruction fetch stage into easy to process control signals like opcode, registers to act on, immediates to use etc. Corresponds to the 2nd stage of the pipeline.

12. **loadStoreMultipleHandler.vhd**  
Consists of `registerFileHandler`, `priorityEncoder`, `LwSwHandler`. Together they implement the microcode generation logic required for the load-multiple (`lm`) and store-multiple (`sm`) instructions.

11. **load_store.vhd**  
Consists of 1 entity called `loadStoreHandler` which handles the load-word (`lw`) and store-word (`sw`) instructions.

12. **main.vhd**  
This is the main file of our design. It instantiates all the stages (instruction fetch, instruction decoder, execute stage, register read/reg fle, data memory, write back, flag registers), the pipeline registers (NBitRegister), the hazard handlers, the branch predictor and wires the up together.

13. **memory.vhdl**  
Singular entity named `memory` which implements a 64 kiB memory. The memory is byte addressable.

14. **register.vhd**  
Singular entity named `NBitRegister`. As the name suggests, allows the implementation of a N-bit register. 

15. **sign_extenders.vhd**  
Singular entity named `signExtender`. Performs sign extension for immediate values.

16. **writeBack.vhd**  
Single entity named `writeBack` which is responsible for generating the register write back signals for the processor. 

*For more details, see the comments in the respective file.
