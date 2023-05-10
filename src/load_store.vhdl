LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY loadStoreHandler IS
    PORT (
        opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        Ra, Rb, Rc : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        RaValue, RbValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        ALU_result : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        ALU_resutWriteEnable : IN STD_LOGIC;

        RAM_Address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        RAM_writeEnable : OUT STD_LOGIC;
        RAM_DataToWrite : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- used for the load instruction
        -- tells us where we have to write the result of the
        -- load instruction, or that of the ALU/branch targets
        writeBackUseRAM_orALU : OUT STD_LOGIC;
        writeBackEnable : OUT STD_LOGIC
    );
END ENTITY loadStoreHandler;

ARCHITECTURE impl OF loadStoreHandler IS
BEGIN

    -- the address to write to is rb+imm
    -- the sum is calculated in the alu
    RAM_Address <= ALU_result;
    -- opcode = "0101" is Store instruction
    RAM_writeEnable <= '1' WHEN opcode = "0101" OR opcode = "0111" ELSE
        '0';
    RAM_DataToWrite <= RaValue;

    -- whether to write the result of ALU calculation or loaded result from RAM
    writeBackUseRAM_orALU <= '1' WHEN opcode = "0100" OR opcode = "0110" ELSE
        '0';

    -- enable writeback when either the ALU also enables writeback 
    -- or it is a load instruction
    writeBackEnable <= '1' WHEN (ALU_resutWriteEnable = '1' OR opcode = "0100" OR opcode = "0011" OR opcode = "0110") ELSE
        '0';
END ARCHITECTURE impl;