LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY instructionDecoder IS
    PORT (

        -- the instruction to be decoded
        instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- the registers on which the task is to be performed.
        -- naming convention is as mentioned in the doc
        Ra, Rb, Rc : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);

        -- 16 bit immediate that is appropriately sign extended
        -- the actual size of the immediate might have been
        -- 9 or 16 bits depending on the instruction.
        immediate : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- the two condition bits required by R type instructions
        condition : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        -- whether to use the complement of Rc
        -- required by R type instructions
        useComplement : OUT STD_LOGIC;

        -- the opcode of the instruction. 
        opcode : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY instructionDecoder;

ARCHITECTURE impl OF instructionDecoder IS

    COMPONENT signExtender IS
        GENERIC (
            IN_WIDTH, OUT_WIDTH : INTEGER
        );
        PORT (
            input : IN STD_LOGIC_VECTOR(IN_WIDTH - 1 DOWNTO 0);
            output : OUT STD_LOGIC_VECTOR(OUT_WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT signExtender;

    SIGNAL imm6_ext, imm9_ext : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

    opcode <= instruction(15 DOWNTO 12);
    useComplement <= instruction(2) WHEN instruction(15 DOWNTO 12) = "0001" OR instruction(15 DOWNTO 12) = "0010" ELSE
        '0';
    condition <= instruction(1 DOWNTO 0);
    Ra <= instruction(11 DOWNTO 9);
    Rb <= instruction(8 DOWNTO 6);
    Rc <= instruction(5 DOWNTO 3);

    SE6to16 : signExtender
    GENERIC MAP(IN_WIDTH => 6, OUT_WIDTH => 16)
    PORT MAP(
        input => instruction(5 DOWNTO 0),
        output => imm6_ext
    );

    SE9to16 : signExtender
    GENERIC MAP(IN_WIDTH => 9, OUT_WIDTH => 16)
    PORT MAP(
        input => instruction(8 DOWNTO 0),
        output => imm9_ext
    );

    WITH instruction(15 DOWNTO 12) SELECT
    -- immediate <= imm6_ext when "0000" | "0100" | "0101" | "1000" | "1001" | "1010",
    -- 				 imm9_ext when "0011" | "0110" | "0111" | "1100" | "1111",
    -- 				 "0000000000000000" when others;
    -- To treat SM as SW and LW as LW
    immediate <= imm6_ext WHEN "0000" | "0100" | "0101" | "1000" | "1001" | "1010" | "0110" | "0111",
        imm9_ext WHEN "0011" | "1100" | "1111",
        "0000000000000000" WHEN OTHERS;

END ARCHITECTURE impl;