library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity memory is
    port(
        RAM_Address : in std_logic_vector(15 downto 0); -- 16 bit address for read/write
        RAM_Data_IN : in std_logic_vector(15 downto 0); -- 16 bit data for write
        RAM_Data_OUT : out std_logic_vector(15 downto 0); -- 16 bit data for read
        RAM_Write : in std_logic; -- write enable
        RAM_Clock : in std_logic -- clock
    );
end memory;

architecture Behavioral of memory is
    -- RAM is a 16 bit x 65536 array of std_logic_vector
    type RAM is array (0 to 65535) of std_logic_vector(15 downto 0);
    -- Initiazation of RAM
    signal RAM_Array : RAM := (others => (others => '0'));
    
begin
    process(RAM_Clock, RAM_Array)
    begin
        if rising_edge(RAM_Clock) then
            if RAM_Write = '1' then
                RAM_Array(to_integer(unsigned(RAM_Address))) <= RAM_Data_IN;
            end if;
            RAM_Data_OUT <= RAM_Array(to_integer(unsigned(RAM_Address)));
        end if;
    end process;
end Behavioral;