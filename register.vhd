library ieee;
use ieee.std_logic_1164.all;

entity NBitRegister is
    generic (
        N: integer;
        default: std_logic := '0'
    );
    port (
        dataIn: in std_logic_vector(N-1 downto 0) := (others => default);
        writeEnable: in std_logic;
        clk: in std_logic;
        asyncReset: in std_logic;
        dataOut: out std_logic_vector(N-1 downto 0) := (others => default)
    );
end entity NBitRegister;

architecture impl of NBitRegister is
begin
    process (clk, asyncReset) begin
        if (asyncReset = '1') then 
            dataOut <= (others => default);
        elsif (rising_edge(clk)) then
            if (writeEnable = '1') then
                dataOut <= dataIn;
            end if;
        end if;
    end process;
end architecture impl;