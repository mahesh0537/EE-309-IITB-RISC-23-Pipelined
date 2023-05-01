library ieee;
use ieee.std_logic_1164.all;

entity signExtender is
	generic (
		IN_WIDTH: integer;
		OUT_WIDTH: integer
	);
	port (
		input: in std_logic_vector(IN_WIDTH-1 downto 0);
		output: out std_logic_vector(OUT_WIDTH-1 downto 0)
	);
end entity signExtender;

architecture struct of signExtender is
begin
	output <= (OUT_WIDTH - IN_WIDTH - 1 downto 0 => input(IN_WIDTH-1)) & input;
end architecture struct;

