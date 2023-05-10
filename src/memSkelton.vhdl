LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY memory IS
    PORT (
        RAM_Address : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit address for read/write
        RAM_Data_IN : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit data for write
        RAM_Data_OUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit data for read
        RAM_Write : IN STD_LOGIC; -- write enable
        RAM_Clock : IN STD_LOGIC -- clock
    );
END memory;

ARCHITECTURE Behavioral OF memory IS
    -- RAM is a 16 bit x 65536 array of std_logic_vector
    TYPE RAM IS ARRAY (0 TO 65535) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    -- Initiazation of RAM
    SIGNAL RAM_Array : RAM := (OTHERS => (OTHERS => '0'));

BEGIN
    PROCESS (RAM_Clock, RAM_Array)
    BEGIN
        IF rising_edge(RAM_Clock) THEN
            IF RAM_Write = '1' THEN
                RAM_Array(to_integer(unsigned(RAM_Address))) <= RAM_Data_IN;
            END IF;
            RAM_Data_OUT <= RAM_Array(to_integer(unsigned(RAM_Address)));
        END IF;
    END PROCESS;
END Behavioral;