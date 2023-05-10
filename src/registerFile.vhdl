LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY regFile IS
    PORT (
        clk : IN STD_LOGIC;
        regWrite : IN STD_LOGIC;
        reg1Addr, reg2Addr, reg3Addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        reg1Data, reg2Data, PC : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        reg3Data, PCtoRF : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        reset : IN STD_LOGIC;
        updatePC : IN STD_LOGIC;
        readPC : IN STD_LOGIC --toggle to read PC, anytime
    );
END regFile;

ARCHITECTURE regFile_arch OF regFile IS
    TYPE regFileType IS ARRAY (0 TO 7) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL regFileArray : regFileType := (OTHERS => (OTHERS => '0'));
    SIGNAL justToTest : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            regFileArray <= (OTHERS => (OTHERS => '0'));
        ELSIF rising_edge(clk) THEN
            IF regWrite = '1' AND updatePC = '1' THEN
                regFileArray(to_integer(unsigned(reg3Addr))) <= reg3Data;
                regFileArray(0) <= PCtoRF;
            ELSIF (NOT regWrite = '1') AND updatePC = '1'THEN
                regFileArray(0) <= PCtoRF;
            ELSIF regWrite = '1' AND (NOT updatePC = '1') THEN
                regFileArray(to_integer(unsigned(reg3Addr))) <= reg3Data;
            END IF;
        END IF;
    END PROCESS;
    reg1Data <= regFileArray(to_integer(unsigned(reg1Addr)));
    reg2Data <= regFileArray(to_integer(unsigned(reg2Addr)));
    PC <= regFileArray(0);
END regFile_arch;