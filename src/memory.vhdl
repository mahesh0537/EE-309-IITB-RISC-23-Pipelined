LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY dataMemory IS
    PORT (
        RAM_Address : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit address for read/write
        RAM_Data_IN : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit data for write
        RAM_Data_OUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit data for read
        RAM_Write : IN STD_LOGIC; -- write enable
        RAM_Clock : IN STD_LOGIC -- clock
    );
END dataMemory;

ARCHITECTURE Behavioral OF dataMemory IS
    -- RAM is a 16 bit x 65536 array of std_logic_vector

    -- shorten the size of this array to reduce compilation time
    TYPE RAM IS ARRAY (0 TO 65536) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- Initiazation of RAM
    SIGNAL RAM_Array : RAM := (OTHERS => (OTHERS => '0'));
BEGIN
    PROCESS (RAM_Clock, RAM_Address, RAM_Array)
    BEGIN
        IF rising_edge(RAM_Clock) THEN
            IF RAM_Write = '1' THEN
                RAM_Array(to_integer(unsigned(RAM_Address))) <= RAM_Data_IN(15 DOWNTO 8);
                RAM_Array((to_integer(unsigned(RAM_Address))) + 1) <= RAM_Data_IN(7 DOWNTO 0);
            END IF;
        END IF;
        RAM_Data_OUT(15 DOWNTO 8) <= RAM_Array(to_integer(unsigned(RAM_Address)));
        RAM_Data_OUT(7 DOWNTO 0) <= RAM_Array((to_integer(unsigned(RAM_Address))) + 1);
    END PROCESS;
END Behavioral;