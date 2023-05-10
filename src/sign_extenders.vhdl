LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY signExtender IS
    GENERIC (
        IN_WIDTH : INTEGER;
        OUT_WIDTH : INTEGER
    );
    PORT (
        input : IN STD_LOGIC_VECTOR(IN_WIDTH - 1 DOWNTO 0);
        output : OUT STD_LOGIC_VECTOR(OUT_WIDTH - 1 DOWNTO 0)
    );
END ENTITY signExtender;

ARCHITECTURE struct OF signExtender IS
BEGIN
    output <= (OUT_WIDTH - IN_WIDTH - 1 DOWNTO 0 => input(IN_WIDTH - 1)) & input;
END ARCHITECTURE struct;