LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY flagReg IS
    PORT (
        clk, reset : IN STD_LOGIC;
        SetZ : IN STD_LOGIC;
        Z : OUT STD_LOGIC;
        SetC : IN STD_LOGIC;
        C : OUT STD_LOGIC
    );
END ENTITY flagReg;

ARCHITECTURE rtl OF flagReg IS
    SIGNAL Z_reg, C_reg : STD_LOGIC := '0';
BEGIN
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            Z_reg <= '0';
            C_reg <= '0';
        ELSIF rising_edge(clk) THEN
            Z_reg <= SetZ;
            C_reg <= SetC;
        END IF;
    END PROCESS;
    Z <= Z_reg;
    C <= C_reg;
END ARCHITECTURE rtl;