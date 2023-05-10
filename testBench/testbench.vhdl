LIBRARY std;
USE std.textio.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY testbench IS
END ENTITY testbench;

ARCHITECTURE whatever OF testbench IS

    COMPONENT CPU_main is 
        port (
            clk: in std_logic
        );
    END COMPONENT CPU_main;

signal clk: std_logic := '0';
BEGIN

	CPUinst: CPU_main port map (
		clk => clk
	);

    PROCESS
        VARIABLE OUTPUT_LINE : line;
        VARIABLE LINE_COUNT : INTEGER := 0;
        VARIABLE i : INTEGER := 0;
        -- FILE OUTFILE : text OPEN write_mode IS "testBench/IF_ID_RegTB.out";

    BEGIN
        WHILE i < 100 LOOP
            clk <= NOT clk;
            WAIT FOR 40 ns;
            i := i + 1;
            clk <= NOT clk;
            WAIT FOR 40 ns;
        END LOOP;
    END PROCESS;


END ARCHITECTURE whatever;