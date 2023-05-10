LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instructionMemory IS
    PORT (
        clk : IN STD_LOGIC;
        address : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        instruction : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ENTITY instructionMemory;

ARCHITECTURE instructions OF instructionMemory IS
    TYPE instructionMemoryDataType IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL instructionMemoryData : instructionMemoryDataType := (

    );
BEGIN
    instruction(15 DOWNTO 8) <= instructionMemoryData(to_integer(unsigned(address)));
    instruction(7 DOWNTO 0) <= instructionMemoryData(to_integer(unsigned(address)) + 1);
END ARCHITECTURE instructions;