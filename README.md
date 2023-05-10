<!This is a markdown file, please open it in a editor (like vscode and open preview) which can render markdown.>

# EE309 Microprocessors Project
This git repository contains our (team 18) submission for the project.

## Simulating the design:
1. To build this file in quartus, include all the (vhdl) files in the `/src` folder, **EXCEPT** `instructionMemSkeleton.vhdl` in the project.
2. Create a file containing the assembly code you want to run. An example file `main.s` is already provided.
3. Compile the assembly file to machine code using the bootloader by running the following command:  
> `python bootloader.py main.s`
4. This will automatically generate the file `instructionMem.vhdl` with the appropriate machine code. If you want to view the machine code, run the assembler directly using the following command:
> `python assembler.py main.s`
6. Note that the build times in quartus can be around 2-3 mins. To shorten this, you may reduce the size of the RAM array (`memory.vhdl`, see the comment).Note however that this may introduce errors in the simulation step.
5. To simulate the design, add `/testBench/testbench.vhdl` as the testbench to be used in quartus and launch modelsim-altera. You can inspect the state of the registers by navigating to `testbench > CPUinst > regFileInstance > regFileArray`. Incase the values are not logged, then click on `simulate > break`. Then enter the following commands and try again:
> `restart -f`  
> `add log -r /*`  
> `run -all`  

## Documentation:
The documentation/report along with the block diagrams can be found in the `documentation` folder.