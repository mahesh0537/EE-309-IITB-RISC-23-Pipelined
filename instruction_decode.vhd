library ieee;
use ieee.std_logic_1164.all;

entity instructionDecoder is
	port(
	
		-- the instruction to be decoded
		instruction: in std_logic_vector(15 downto 0);
		
		-- the registers on which the task is to be performed.
		-- naming convention is as mentioned in the doc
		Ra, Rb, Rc: out std_logic_vector(2 downto 0);
		
		-- 16 bit immediate that is appropriately sign extended
		-- the actual size of the immediate might have been
		-- 9 or 16 bits depending on the instruction.
		immediate: out std_logic_vector(15 downto 0);
		
		-- the two condition bits required by R type instructions
		condition: out std_logic_vector(1 downto 0);
		
		-- whether to use the complement of Rc
		-- required by R type instructions
		useComplement: out std_logic;
		
		-- the opcode of the instruction. 
		opcode: out std_logic_vector(3 downto 0)
	);
end entity instructionDecoder;

architecture impl of instructionDecoder is

	component signExtender is
		generic(
			IN_WIDTH, OUT_WIDTH: integer
		);
		port(
			input: in std_logic_vector(IN_WIDTH-1 downto 0);
			output: out std_logic_vector(OUT_WIDTH-1 downto 0)
		);
	end component signExtender;

	signal imm6_ext, imm9_ext: std_logic_vector(15 downto 0);
begin

	opcode <= instruction(15 downto 12);
	useComplement <= instruction(2) when instruction(15 downto 12) = "0001" or instruction(15 downto 12) = "0010" else '0';
	condition <= instruction(1 downto 0);
	
	
	Ra <= instruction(11 downto 9);
	Rb <= instruction(8 downto 6);
	Rc <= instruction(5 downto 3);

SE6to16: signExtender
	generic map(IN_WIDTH => 6, OUT_WIDTH => 16)
	port map(
		input => instruction(5 downto 0),
		output => imm6_ext
	);

SE9to16: signExtender
	generic map(IN_WIDTH => 9, OUT_WIDTH => 16)
	port map(
		input => instruction(8 downto 0),
		output => imm9_ext
	);
	
with instruction(15 downto 12) select
	-- immediate <= imm6_ext when "0000" | "0100" | "0101" | "1000" | "1001" | "1010",
	-- 				 imm9_ext when "0011" | "0110" | "0111" | "1100" | "1111",
	-- 				 "0000000000000000" when others;
	-- To treat SM as SW and LW as LW
	immediate <= imm6_ext when "0000" | "0100" | "0101" | "1000" | "1001" | "1010" | "0110" | "0111",
					 imm9_ext when "0011" | "1100" | "1111",
					 "0000000000000000" when others;
	
end architecture impl;