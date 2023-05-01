library ieee;
use ieee.std_logic_1164.all;

entity mux2 is
    port (
        data0, data1 : in std_logic_vector(15 downto 0);
        sel : in std_logic;
        data_out : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of mux2 is
begin
    data_out <= data0 when sel = '0' else data1;
end rtl;