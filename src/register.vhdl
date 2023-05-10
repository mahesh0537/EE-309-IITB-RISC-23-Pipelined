LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY NBitRegister IS
    GENERIC (
        N : INTEGER;
        DEFAULT : STD_LOGIC := '0'
    );
    PORT (
        dataIn : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0) := (OTHERS => DEFAULT);
        writeEnable : IN STD_LOGIC;
        clk : IN STD_LOGIC;
        asyncReset : IN STD_LOGIC;
        dataOut : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0) := (OTHERS => DEFAULT)
    );
END ENTITY NBitRegister;

ARCHITECTURE impl OF NBitRegister IS
BEGIN
    PROCESS (clk, asyncReset) BEGIN
        IF (asyncReset = '1') THEN
            dataOut <= (OTHERS => DEFAULT);
        ELSIF (rising_edge(clk)) THEN
            IF (writeEnable = '1') THEN
                dataOut <= dataIn;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE impl;