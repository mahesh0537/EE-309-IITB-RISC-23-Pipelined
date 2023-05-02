library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DataHazardDetector is
	port (
		-- the register whose operands are going to be used to
		-- execute the instruction. it is the input to the execute stage
		currentRegister: in std_logic_vector(2 downto 0);
		currentOpcode: in std_logic_vector(3 downto 0);
		
		-- the register to which the execute stage's result is to be written
		-- same nomenclature for other stages
		execute_opcode: in std_logic_vector(3 downto 0);
		execute_RegToWrite: in std_logic_vector(2 downto 0);
		execute_WriteEnable: in std_logic;
		
		mem_opcode: in std_logic_vector(3 downto 0);
		mem_RegToWrite: in std_logic_vector(2 downto 0);
		mem_WriteEnable: in std_logic;
		
		writeBack_opcode: in std_logic_vector(3 downto 0);
		writeBack_RegToWrite: in std_logic_vector(2 downto 0);
		writeBack_writeEnable: in std_logic;
	
		execute_hasHazard: out std_logic;
		mem_hasHazard: out std_logic;
		writeBack_hasHazard: out std_logic;
		
		-- '0' if it is arithmetic hazard and '1' if it is load hazard
		-- in case of load hazard of immediate dependency, we will have
		-- to stall the pipeline for 1 instruction
--		hazardType: out std_logic;

		-- when there is a load hazard of immediate dependency, we will
		-- have to pause the pipeline for 1 cycle. essentially the same as
		-- introducing a bubble.
		insertBubbleInPipeline: out std_logic
	);
end entity DataHazardDetector;

architecture impl of DataHazardDetector is
signal mem_hasArithHazard, mem_hasLoadHazard: std_logic;
signal execute_hasHazard_temp, mem_hasArithHazard_temp, writeBack_hasHazard_temp: std_logic;
begin

	with  execute_WriteEnable & execute_opcode select
		execute_hasHazard_temp <= '1' when
				'1' & "0001" |	-- adds
				'1' & "0000" |	-- adi
				'1' & "0010" |	-- nands
				'1' & "0011" |	-- lli
				'1' & "1100" |	-- jal
				'1' & "1101",	-- jlr
			'0' when others;
	execute_hasHazard <= '1' when (execute_hasHazard_temp = '1') and (execute_RegToWrite = currentRegister) else '0';
	
	with  mem_WriteEnable & mem_opcode select
		mem_hasArithHazard_temp <= '1' when
				'1' & "0001" |	-- adds
				'1' & "0000" |	-- adi
				'1' & "0010" |	-- nands
				'1' & "0011" |	-- lli
				'1' & "1100" |	-- jal
				'1' & "1101", 	-- jlr
			'0' when others;
	
	mem_hasArithHazard <= '1' when (mem_hasArithHazard_temp = '1') and currentRegister = mem_regToWrite else '0';
	mem_hasLoadHazard <= '1' when (currentRegister = mem_RegToWrite) and (currentOpcode = "0010") else '0';
	mem_hasHazard <= mem_hasArithHazard or mem_hasLoadHazard;
	
	with  writeBack_WriteEnable & writeBack_opcode select
		writeBack_hasHazard_temp <= '1' when
				'1' & "0001" |	-- adds
				'1' & "0000" |	-- adi
				'1' & "0010" |	-- nands
				'1' & "0011" |	-- lli
				'1' & "1100" |	-- jal
				'1' & "1101",	-- jlr
			'0' when others;
	writeBack_hasHazard <= '1' when (writeBack_hasHazard_temp = '1') and currentRegister = writeBack_RegToWrite else '0';
	
	
	insertBubbleInPipeline <= '1' when (currentRegister = execute_regToWrite and execute_opcode = "0010") else '0';
	
end architecture impl;

library ieee;
use ieee.std_logic_1164.all;

entity dataForwarder is
	port(
		-- the opcode of the instruction that is going to be executed
		currentOpcode: in std_logic_vector(3 downto 0);
		
		-- the two inputs to the execute stage
		currentRegisterA: in std_logic_vector(2 downto 0);
		currentRegisterAValue: in std_logic_vector(15 downto 0);
		currentRegisterB: in std_logic_vector(2 downto 0);
		currentRegisterBValue: in std_logic_vector(15 downto 0);
		
		execute_RegToWrite: in std_logic_vector(2 downto 0);
		execute_WriteEnable: in std_logic;
		execute_RegValue: in std_logic_vector(15 downto 0);
		execute_opcode: in std_logic_vector(3 downto 0);
		mem_RegToWrite: in std_logic_vector(2 downto 0);
		mem_WriteEnable: in std_logic;
		mem_RegValue: in std_logic_vector(15 downto 0);
		mem_opcode: in std_logic_vector(3 downto 0);
		writeBack_RegToWrite: in std_logic_vector(2 downto 0);
		writeBack_WriteEnable: in std_logic;
		writeBack_RegValue: in std_logic_vector(15 downto 0);
		writeBack_opcode: in std_logic_vector(3 downto 0);
		
		dataToUseAfterAccountingHazardsRegA: out std_logic_vector(15 downto 0);
		dataToUseAfterAccountingHazardsRegB: out std_logic_vector(15 downto 0);
		
		insertBubbleInPipeline: out std_logic
	);
end entity dataForwarder;

architecture impl of dataForwarder is
component DataHazardDetector is
	port (
		currentRegister: in std_logic_vector(2 downto 0);
		currentOpcode: in std_logic_vector(3 downto 0);
		
		execute_opcode: in std_logic_vector(3 downto 0);
		execute_RegToWrite: in std_logic_vector(2 downto 0);
		execute_WriteEnable: in std_logic;
		
		mem_opcode: in std_logic_vector(3 downto 0);
		mem_RegToWrite: in std_logic_vector(2 downto 0);
		mem_WriteEnable: in std_logic;
		
		writeBack_opcode: in std_logic_vector(3 downto 0);
		writeBack_RegToWrite: in std_logic_vector(2 downto 0);
		writeBack_writeEnable: in std_logic;
	
		execute_hasHazard: out std_logic;
		mem_hasHazard: out std_logic;
		writeBack_hasHazard: out std_logic;
		
--		hazardType: out std_logic;
		insertBubbleInPipeline: out std_logic
	);
end component DataHazardDetector;

signal execute_hasHazard_regA, mem_hasHazard_regA, writeBack_hasHazard_regA, hazardType_regA, bubble_regA: std_logic;
signal execute_hasHazard_regB, mem_hasHazard_regB, writeBack_hasHazard_regB, hazardType_regB, bubble_regB: std_logic;
begin
	
	dataHazardDetectorForRegA: dataHazardDetector
		port map (
			currentOpcode => currentOpcode,
			currentRegister => currentRegisterA,
			execute_opcode => execute_opcode,
			execute_RegToWrite => execute_RegToWrite,
			execute_WriteEnable => execute_WriteEnable,
			mem_opcode => mem_opcode,
			mem_RegToWrite => mem_RegToWrite,
			mem_WriteEnable => mem_WriteEnable,
			writeBack_opcode => writeBack_opcode,
			writeBack_RegToWrite => writeBack_RegToWrite,
			writeBack_writeEnable => writeBack_writeEnable,
			execute_hasHazard => execute_hasHazard_regA,
			mem_hasHazard => mem_hasHazard_regA,
			writeBack_hasHazard => writeBack_hasHazard_regA,
			insertBubbleInPipeline => bubble_regA
		);
		
	dataHazardDetectorForRegB: dataHazardDetector
		port map (
			currentOpcode => currentOpcode,
			currentRegister => currentRegisterB,
			execute_opcode => execute_opcode,
			execute_RegToWrite => execute_RegToWrite,
			execute_WriteEnable => execute_WriteEnable,
			mem_opcode => mem_opcode,
			mem_RegToWrite => mem_RegToWrite,
			mem_WriteEnable => mem_WriteEnable,
			writeBack_opcode => writeBack_opcode,
			writeBack_RegToWrite => writeBack_RegToWrite,
			writeBack_writeEnable => writeBack_writeEnable,
			execute_hasHazard => execute_hasHazard_regB,
			mem_hasHazard => mem_hasHazard_regB,
			writeBack_hasHazard => writeBack_hasHazard_regB,
			insertBubbleInPipeline => bubble_regB
		);
	
	-- hazards may be present in more than 1 stage
	-- in that case we have to pick the result in the 
	-- following order (decreasing priority):
	-- Execute, Memory, writeback
	dataToUseAfterAccountingHazardsRegA <= execute_RegValue when execute_hasHazard_regA = '1' else
														mem_RegValue when mem_hasHazard_regA = '1' else
														writeBack_RegValue when writeBack_hasHazard_regA = '1' else
														currentRegisterAValue;
	
	dataToUseAfterAccountingHazardsRegB <= execute_RegValue when execute_hasHazard_regB = '1' else
														mem_RegValue when mem_hasHazard_regB = '1' else
														writeBack_RegValue when writeBack_hasHazard_regB = '1' else
														currentRegisterBValue;
													
	insertBubbleInPipeline <= bubble_regA or bubble_regB;
end architecture impl;
