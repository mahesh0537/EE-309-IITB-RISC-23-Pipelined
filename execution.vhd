library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execStage is
	port(
		opcode: in std_logic_vector(3 downto 0);
		Ra, Rb, Rc: in std_logic_vector(2 downto 0);
		RaValue, RbValue: in std_logic_vector(15 downto 0);
		immediate: in std_logic_vector(15 downto 0);
		condition: in std_logic_vector(1 downto 0);
		useComplement: in std_logic;
		PC: in std_logic_vector(15 downto 0);

		-- this PC is to be used when a branch instruction is
		-- executed. otherwise, the default update is to be performed
		-- i.e. PC <- PC + 2
		PC_new: out std_logic_vector(15 downto 0);
		useNewPc: out std_logic;

		-- the new value of the register and wheter to write to it
		regNewValue: out std_logic_vector(15 downto 0);
		regToWrite: out std_logic_vector(2 downto 0);
		writeReg: out std_logic;

		zeroFlagIn: in std_logic;
		zeroFlagOut: out std_logic;
--		zeroFlagWriteEnable: in std_logic;

		carryFlagIn: in std_logic;
		carryFlagOut: out std_logic;
--		carryFlagWriteEnable: in std_logic;
		
		-- writing the result to RAM, instead of register file
		RAM_Address: out std_logic_vector(15 downto 0);
		RAM_writeEnable: out std_logic;
		RAM_DataToWrite: out std_logic_vector(15 downto 0);
		
		-- used for the load instruction
		-- tells us where we have to write the result of the
		-- load instruction, or that of the ALU/branch targets
		-- '1' is for RAM, '0' is for ALU
		writeBackUseRAM_orALU: out std_logic;
		writeBackEnable: out std_logic;
		
		stallInstructionRead: out std_logic;
		beenFlushed: in std_logic
	);
end entity execStage;

architecture impl of execStage is
component ALU_wrapper is
	port (
		RaValue, RbValue, immediate: in std_logic_vector(15 downto 0);
		opcode: in std_logic_vector(3 downto 0);
		condition: in std_logic_vector(1 downto 0);
		compliment: in std_logic;
		ZF_prev, CF_prev: in std_logic;

		result: out std_logic_vector(15 downto 0);
		ZF, CF: out std_logic;
		useResult: out std_logic
	);
end component ALU_wrapper;

component conditionalBranchHandler is
	port (
		opcode: in std_logic_vector(3 downto 0);
		Ra, Rb: in std_logic_vector(15 downto 0);
		imm: in std_logic_vector(15 downto 0);
		PC: in std_logic_vector(15 downto 0);
		
		PC_new: out std_logic_vector(15 downto 0);
		useNewPc: out std_logic
	);
end component conditionalBranchHandler;

component unconditionalBranchHandler is
	port(
		opcode: in std_logic_vector(3 downto 0);
		PC: in std_logic_vector(15 downto 0);
		Ra, Rb, immediate: in std_logic_vector(15 downto 0);

		RA_new: out std_logic_vector(15 downto 0);
		PC_new: out std_logic_vector(15 downto 0);
		useNewPc, useNewRa: out std_logic
	);
end component unconditionalBranchHandler;

component loadStoreHandler
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
		writeBackUseRAM_orALU: out std_logic;
		writeBackEnable: out std_logic
	);
end component loadStoreHandler;

signal ALU_ZF, ALU_CF: std_logic;
signal ALU_result: std_logic_vector(15 downto 0);
signal ALU_useResult: std_logic;
--signal ALU_A, ALU_B: std_logic_vector(15 downto 0);

--signal m_ZeroFlag: std_logic := '0';
--signal m_CarryFlag: std_logic := '0';

-- CB is conditional Branch, UCB is unconditional branch
signal CB_PC_new, UCB_PC_new: std_logic_vector(15 downto 0);
signal CB_useNewPC, UCB_useNewPC: std_logic;
signal UCB_useNewRa: std_logic;
signal UCB_RA_new: std_logic_vector(15 downto 0);

signal PC_plus2: std_logic_vector(15 downto 0);
begin
	
	ALU_wrapperInstance: ALU_wrapper
		port map (
			RaValue => RaValue,
			RbValue => RbValue,
			immediate => immediate,
			opcode => opcode,
			condition => condition,
			ZF_prev => ZeroFlagIn,
			CF_prev => CarryFlagIn,
			compliment => useComplement,
			
			result => ALU_result,
			ZF => ALU_ZF,
			CF => ALU_CF,
			useResult => ALU_useResult
		);
	
	UCBH_instance: unconditionalBranchHandler
		port map (
			opcode => opcode,
			PC => PC,
			Ra => RaValue,
			Rb => RbValue,
			immediate => immediate,
			
			Ra_new => UCB_RA_new,
			PC_new => UCB_PC_new,
			useNewPc => UCB_useNewPC,
			useNewRa => UCB_useNewRa
		);
	
	CBH_instance: conditionalBranchHandler
		port map (
			opcode => opcode,
			Ra => RaValue,
			Rb => RbValue,
			imm => immediate,
			PC => PC,
			
			PC_new => CB_PC_new,
			useNewPc => CB_useNewPC
		);
	
	LSH_instance: loadStoreHandler
		port map(
			opcode => opcode,
			Ra => Ra,
			Rb => Rb,
			Rc => Rc,
			RaValue => RaValue,
			RbValue => RbValue,
			immediate => immediate,
			ALU_result => ALU_result,
			ALU_resutWriteEnable => ALU_useResult,
			RAM_Address => RAM_Address,
			RAM_writeEnable => RAM_writeEnable,
			RAM_DataToWrite => RAM_DataToWrite,
			writeBackUseRAM_orALU => writeBackUseRAM_orALU,
			writeBackEnable => writeBackEnable
		);
	
	zeroFlagOut <= ALU_ZF when ALU_useResult = '1' else zeroFlagIn;
	carryFlagOut <= ALU_CF when ALU_useResult = '1' else carryFlagIn;					
	
	-- whether we use the new result or not is decided by the writeReg flag
	regNewValue <= ALU_result when ALU_useResult = '1' else
						UCB_RA_new when UCB_useNewRa = '1' else
						ALU_result when opcode = "0011" else
						"0000000000000000";
	
	regToWrite <= 	Rc when (ALU_useResult = '1' and (opcode = "0001" or opcode = "0010")) else -- Rtype ADD and Rtype NAND instructions
						Ra when (ALU_useResult = '1' and opcode = "0000") else
						Ra when (UCB_useNewPC = '1') else 
						Ra when opcode = "0011" or opcode = "0110" else "111";	-- lli instruction
	
	writeReg <= '1' when ALU_useResult = '1' and beenFlushed = '0' else
					'0' when CB_useNewPC = '1' else
					UCB_useNewRa when UCB_useNewPC = '1' and beenFlushed = '0' else
					'1' when opcode = "0011" and beenFlushed = '0' else '0';
	
	PC_new <= 	"0000000000000000" when ALU_useResult = '1' else
					CB_PC_new when CB_useNewPC = '1' else
					UCB_PC_new when UCB_useNewPC = '1' else
					"0000000000000000";
	
	useNewPc <= '0' when ALU_useResult = '1' else
					'1' when CB_useNewPC = '1' else
					'1' when UCB_useNewPC = '1' else '0';

	-- will use later when pipelining
	stallInstructionRead <= '0';
end architecture impl;