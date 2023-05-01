library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instructionMemory is
    port(
        clk : in std_logic;
        address : in std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(15 downto 0)
    );
end entity instructionMemory;

architecture instructions of instructionMemory is
    type instructionMemoryDataType is array (0 to 255) of std_logic_vector(7 downto 0);
    signal instructionMemoryData : instructionMemoryDataType := (
  
    );
begin 
instruction(15 downto 8) <= instructionMemoryData(to_integer(unsigned(address)));
instruction(7 downto 0) <= instructionMemoryData(to_integer(unsigned(address))+1);
end architecture instructions;