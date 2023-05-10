LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mux2 IS
    PORT (
        data0, data1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        sel : IN STD_LOGIC;
        data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF mux2 IS
BEGIN
    data_out <= data0 WHEN sel = '0' ELSE
        data1;
END rtl;