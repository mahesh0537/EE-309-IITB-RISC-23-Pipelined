LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY DataHazardDetector IS
    PORT (
        -- the register whose operands are going to be used to
        -- execute the instruction. it is the input to the execute stage
        currentRegister : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        currentOpcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- the register to which the execute stage's result is to be written
        -- same nomenclature for other stages
        execute_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        execute_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        execute_WriteEnable : IN STD_LOGIC;

        mem_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        mem_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_WriteEnable : IN STD_LOGIC;

        writeBack_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        writeBack_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        writeBack_writeEnable : IN STD_LOGIC;

        execute_hasHazard : OUT STD_LOGIC;
        mem_hasHazard : OUT STD_LOGIC;
        writeBack_hasHazard : OUT STD_LOGIC;

        -- '0' if it is arithmetic hazard and '1' if it is load hazard
        -- in case of load hazard of immediate dependency, we will have
        -- to stall the pipeline for 1 instruction
        --		hazardType: out std_logic;

        -- when there is a load hazard of immediate dependency, we will
        -- have to pause the pipeline for 1 cycle. essentially the same as
        -- introducing a bubble.
        insertBubbleInPipeline : OUT STD_LOGIC
    );
END ENTITY DataHazardDetector;

ARCHITECTURE impl OF DataHazardDetector IS
    SIGNAL mem_hasArithHazard, mem_hasLoadHazard : STD_LOGIC;
    SIGNAL execute_hasHazard_temp, mem_hasArithHazard_temp, writeBack_hasHazard_temp : STD_LOGIC;
BEGIN

    WITH execute_WriteEnable & execute_opcode SELECT
    execute_hasHazard_temp <= '1' WHEN
        '1' & "0001" | -- adds
        '1' & "0000" | -- adi
        '1' & "0010" | -- nands
        '1' & "0011" | -- lli
        '1' & "1100" | -- jal
        '1' & "1101" | -- jlr
        '1' & "0111", -- lm
        '0' WHEN OTHERS;
    execute_hasHazard <= '1' WHEN (execute_hasHazard_temp = '1') AND (execute_RegToWrite = currentRegister) ELSE
        '0';

    WITH mem_WriteEnable & mem_opcode SELECT
    mem_hasArithHazard_temp <= '1' WHEN
        '1' & "0001" | -- adds
        '1' & "0000" | -- adi
        '1' & "0010" | -- nands
        '1' & "0011" | -- lli
        '1' & "1100" | -- jal
        '1' & "1101" | -- jlr
        '1' & "0111", -- lm
        '0' WHEN OTHERS;

    mem_hasArithHazard <= '1' WHEN (mem_hasArithHazard_temp = '1') AND (currentRegister = mem_regToWrite) ELSE
        '0';
    mem_hasLoadHazard <= '1' WHEN (currentRegister = mem_RegToWrite) AND ((mem_opcode = "0100") OR (mem_opcode = "0110")) ELSE
        '0';
    mem_hasHazard <= mem_hasArithHazard OR mem_hasLoadHazard;

    WITH writeBack_WriteEnable & writeBack_opcode SELECT
    writeBack_hasHazard_temp <= '1' WHEN
        '1' & "0001" | -- adds
        '1' & "0000" | -- adi
        '1' & "0010" | -- nands
        '1' & "0011" | -- lli
        '1' & "1100" | -- jal
        '1' & "1101" | -- jlr
        '1' & "0111", -- lm
        '0' WHEN OTHERS;
    writeBack_hasHazard <= '1' WHEN (writeBack_hasHazard_temp = '1') AND (currentRegister = writeBack_RegToWrite) ELSE
        '0';
    insertBubbleInPipeline <= '1' WHEN (((currentRegister = execute_regToWrite) AND ((execute_opcode = "0100") OR (execute_opcode = "0110"))) AND execute_WriteEnable = '1') ELSE
        '0';

END ARCHITECTURE impl;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dataForwarder IS
    PORT (
        -- the opcode of the instruction that is going to be executed
        currentOpcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- the two inputs to the execute stage
        currentRegisterA : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        currentRegisterAValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        currentRegisterB : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        currentRegisterBValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        execute_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        execute_WriteEnable : IN STD_LOGIC;
        execute_RegValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        execute_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        mem_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        mem_WriteEnable : IN STD_LOGIC;
        mem_RegValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        mem_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        writeBack_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        writeBack_WriteEnable : IN STD_LOGIC;
        writeBack_RegValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        writeBack_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        dataToUseAfterAccountingHazardsRegA : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dataToUseAfterAccountingHazardsRegB : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        insertBubbleInPipeline : OUT STD_LOGIC
    );
END ENTITY dataForwarder;

ARCHITECTURE impl OF dataForwarder IS
    COMPONENT DataHazardDetector IS
        PORT (
            currentRegister : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            currentOpcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

            execute_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            execute_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            execute_WriteEnable : IN STD_LOGIC;

            mem_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            mem_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            mem_WriteEnable : IN STD_LOGIC;

            writeBack_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            writeBack_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            writeBack_writeEnable : IN STD_LOGIC;

            execute_hasHazard : OUT STD_LOGIC;
            mem_hasHazard : OUT STD_LOGIC;
            writeBack_hasHazard : OUT STD_LOGIC;

            --		hazardType: out std_logic;
            insertBubbleInPipeline : OUT STD_LOGIC
        );
    END COMPONENT DataHazardDetector;

    SIGNAL execute_hasHazard_regA, mem_hasHazard_regA, writeBack_hasHazard_regA, hazardType_regA, bubble_regA : STD_LOGIC;
    SIGNAL execute_hasHazard_regB, mem_hasHazard_regB, writeBack_hasHazard_regB, hazardType_regB, bubble_regB : STD_LOGIC;
BEGIN

    dataHazardDetectorForRegA : dataHazardDetector
    PORT MAP(
        currentOpcode => currentOpcode,
        currentRegister => currentRegisterA,
        execute_opcode => execute_opcode,
        execute_RegToWrite => execute_RegToWrite,
        execute_WriteEnable => execute_WriteEnable,
        mem_opcode => mem_opcode,
        mem_RegToWrite => mem_RegToWrite,
        mem_WriteEnable => mem_WriteEnable,
        writeBack_opcode => writeBack_opcode,
        writeBack_RegToWrite => writeBack_RegToWrite,
        writeBack_writeEnable => writeBack_writeEnable,
        execute_hasHazard => execute_hasHazard_regA,
        mem_hasHazard => mem_hasHazard_regA,
        writeBack_hasHazard => writeBack_hasHazard_regA,
        insertBubbleInPipeline => bubble_regA
    );

    dataHazardDetectorForRegB : dataHazardDetector
    PORT MAP(
        currentOpcode => currentOpcode,
        currentRegister => currentRegisterB,
        execute_opcode => execute_opcode,
        execute_RegToWrite => execute_RegToWrite,
        execute_WriteEnable => execute_WriteEnable,
        mem_opcode => mem_opcode,
        mem_RegToWrite => mem_RegToWrite,
        mem_WriteEnable => mem_WriteEnable,
        writeBack_opcode => writeBack_opcode,
        writeBack_RegToWrite => writeBack_RegToWrite,
        writeBack_writeEnable => writeBack_writeEnable,
        execute_hasHazard => execute_hasHazard_regB,
        mem_hasHazard => mem_hasHazard_regB,
        writeBack_hasHazard => writeBack_hasHazard_regB,
        insertBubbleInPipeline => bubble_regB
    );

    -- hazards may be present in more than 1 stage
    -- in that case we have to pick the result in the 
    -- following order (decreasing priority):
    -- Execute, Memory, writeback
    dataToUseAfterAccountingHazardsRegA <= execute_RegValue WHEN execute_hasHazard_regA = '1' ELSE
        mem_RegValue WHEN mem_hasHazard_regA = '1' ELSE
        writeBack_RegValue WHEN writeBack_hasHazard_regA = '1' ELSE
        currentRegisterAValue;

    dataToUseAfterAccountingHazardsRegB <= execute_RegValue WHEN execute_hasHazard_regB = '1' ELSE
        mem_RegValue WHEN mem_hasHazard_regB = '1' ELSE
        writeBack_RegValue WHEN writeBack_hasHazard_regB = '1' ELSE
        currentRegisterBValue;

    insertBubbleInPipeline <= bubble_regA OR bubble_regB;
END ARCHITECTURE impl;