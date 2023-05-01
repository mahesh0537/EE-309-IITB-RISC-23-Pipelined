library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity loadStoreHandler is
	port(
		opcode: in std_logic_vector(3 downto 0);
		Ra, Rb, Rc: in std_logic_vector(2 downto 0);
		RaValue, RbValue: in std_logic_vector(15 downto 0);
		immediate: in std_logic_vector(15 downto 0);
		ALU_result: in std_logic_vector(15 downto 0);
		ALU_resutWriteEnable: in std_logic;
		
		RAM_Address: out std_logic_vector(15 downto 0);
		RAM_writeEnable: out std_logic;
		RAM_DataToWrite: out std_logic_vector(15 downto 0);
		
		-- used for the load instruction
		-- tells us where we have to write the result of the
		-- load instruction, or that of the ALU/branch targets
		writeBackUseRAM_orALU: out std_logic;
		writeBackEnable: out std_logic
	);
end entity loadStoreHandler;

architecture impl of loadStoreHandler is
begin
	
	-- the address to write to is rb+imm
	-- the sum is calculated in the alu
	RAM_Address <= ALU_result;
	-- opcode = "0101" is Store instruction
	RAM_writeEnable <= '1' when opcode = "0101" else '0';
	RAM_DataToWrite <= RaValue;
	
	-- whether to write the result of ALU calculation or loaded result from RAM
	writeBackUseRAM_orALU <= '1' when opcode = "0100" else '0';
	
	-- enable writeback when either the ALU also enables writeback 
	-- or it is a load instruction
	writeBackEnable <= '1' when (ALU_resutWriteEnable = '1' or opcode = "0100" or opcode = "0011") else '0';
end architecture impl;