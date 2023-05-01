library ieee;
use ieee.std_logic_1164.all;

entity flagReg is
    port (
        clk, reset : in std_logic;
        SetZ : in std_logic;
        Z : out std_logic;
        SetC : in std_logic;
        C : out std_logic
    );
end entity flagReg;

architecture rtl of flagReg is
    signal Z_reg, C_reg : std_logic := '0';
begin
    process (clk, reset)
    begin
        if reset = '1' then
            Z_reg <= '0';
            C_reg <= '0';
        elsif rising_edge(clk) then
            Z_reg <= SetZ;
            C_reg <= SetC;
        end if;
    end process;
Z <= Z_reg;
C <= C_reg;
end architecture rtl;