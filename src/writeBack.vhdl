LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY writeBack IS
    PORT (
        clk : IN STD_LOGIC;
        writeSignal : IN STD_LOGIC;
        writeSignalOut : OUT STD_LOGIC;
        selectSignalEx_RAM : IN STD_LOGIC;
        writeDataIN_Ex : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        writeDataIN_RAM : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        writeDataOUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        writeAddressIN : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        writeAddressOUT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        GotFlushed : IN STD_LOGIC
    );
END ENTITY;

ARCHITECTURE arch OF writeBack IS
BEGIN
    writeDataOUT <= writeDataIN_Ex WHEN selectSignalEx_RAM = '0' ELSE
        writeDataIN_RAM;
    writeSignalOut <= writeSignal WHEN GotFlushed = '0' ELSE
        '0';
    writeAddressOUT <= writeAddressIN;
END arch;