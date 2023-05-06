library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity conditionalBranchHandler is
	port (
		opcode: in std_logic_vector(3 downto 0);
		Ra, Rb: in std_logic_vector(15 downto 0);
		imm: in std_logic_vector(15 downto 0);
		PC: in std_logic_vector(15 downto 0);
		
		PC_new: out std_logic_vector(15 downto 0);
		useNewPc: out std_logic
	);
end entity conditionalBranchHandler;

architecture impl of conditionalBranchHandler is
signal m_branchTakenResult: std_logic_vector(15 downto 0);
signal m_branchNotTakenResult: std_logic_vector(15 downto 0);
signal m_Ra, m_Rb: unsigned(15 downto 0);
begin
	m_Ra <= unsigned(Ra);
	m_Rb <= unsigned(Rb);
	m_branchTakenResult <= std_logic_vector(unsigned(PC) + unsigned(imm) + unsigned(imm));
	m_branchNotTakenResult <= std_logic_vector(unsigned(PC) + 2);
	PC_new <= m_branchTakenResult when (
		((opcode = "1000") and (m_Ra = m_Rb)) or
		((opcode = "1001") and (m_Ra < m_Rb)) or
		((opcode = "1010") and (m_Ra <= m_Rb))
	) else m_branchNotTakenResult;
	
	-- useNewPc <= '1' when (
	-- 	(opcode = "1000") or
	-- 	(opcode = "1001") or
	-- 	(opcode = "1010")
	-- ) else '0';
	useNewPc <= '1' when (
	((opcode = "1000") and (m_Ra = m_Rb)) or
	((opcode = "1001") and (m_Ra < m_Rb)) or
	((opcode = "1010") and (m_Ra <= m_Rb))
	) else '0';

end architecture impl;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity unconditionalBranchHandler is
	port(
		opcode: in std_logic_vector(3 downto 0);
		PC: in std_logic_vector(15 downto 0);
		Ra, Rb, immediate: in std_logic_vector(15 downto 0);
		
		RA_new: out std_logic_vector(15 downto 0);
		PC_new: out std_logic_vector(15 downto 0);
		useNewPc, useNewRa: out std_logic
	);
end entity unconditionalBranchHandler;

architecture impl of unconditionalBranchHandler is
begin
	PC_new <= 	std_logic_vector(unsigned(PC) + unsigned(immediate) + unsigned(immediate)) when opcode = "1100" else	-- jal
					Rb when opcode = "1101" else																-- jlr
					std_logic_vector(unsigned(Ra) + unsigned(immediate) + unsigned(immediate));								-- jri
					
	-- use these results only if the opcode corresponds to a unconditional branch instruction
	useNewPc <= '1' when (
		(opcode = "1100") or	-- jal
		(opcode = "1101") or	-- jlr
		(opcode = "1111")		-- jri
	) else '0';
	
	RA_new <= std_logic_vector(unsigned(PC) + 2);
	useNewRa <= '1' when (opcode = "1100" or opcode = "1101") else '0'; 
	
	
end architecture impl;