library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- we need an extra adder to precompute the branch targets
entity branchPredictorALU is
	port (
		opcode: in std_logic_vector(3 downto 0);
		PC, imm: in std_logic_vector(15 downto 0);
		branchPredictor_prediction: in std_logic;
		
		branchTarget: out std_logic_vector(15 downto 0)
	);
end entity branchPredictorALU;

architecture impl of branchPredictorALU is
signal adderA, adderB: std_logic_vector(15 downto 0);
signal immTimes2: std_logic_vector(15 downto 0);
begin
	-- left shift by 1 is same as multiplying by 2
	immTimes2 <= imm(14 downto 0) & '0';
	adderA <= PC;
	
	with opcode & branchPredictor_prediction select
		adderB <= 	
			immTimes2 when 
				"1000" & '1' |
				"1001" & '1' |
				"1010" & '1' | 
				"1100" & '1',
			"0000000000000010" when others;
	
	branchTarget <= std_logic_vector(unsigned(adderA) + unsigned(adderB));

end architecture impl;


library ieee;
use ieee.std_logic_1164.all;

package branchPredictorDeclarations is
	type branchHistory is (StronglyTaken, WeaklyTaken, WeaklyNotTaken, StronglyNotTaken);
	type PC_array_t is array(0 to 7) of std_logic_vector(15 downto 0);
	type branchHistoryArray_t is array(0 to 7) of branchHistory;
end package branchPredictorDeclarations;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.branchPredictorDeclarations.all;

entity branchComparator is
	port (
		PChistory: in PC_array_t;
		PCtoPredict: in std_logic_vector(15 downto 0);
		index: out integer;
		isFound: out std_logic
	);
end entity branchComparator;

architecture impl of branchComparator is
signal index_temp: integer;
begin
	index_temp <= 0 when PChistory(0) = PCtoPredict else
				1 when PChistory(1) = PCtoPredict else
				2 when PChistory(2) = PCtoPredict else
				3 when PChistory(3) = PCtoPredict else
				4 when PChistory(4) = PCtoPredict else
				5 when PChistory(5) = PCtoPredict else
				6 when PChistory(6) = PCtoPredict else
				7 when PChistory(7) = PCtoPredict else 8;
	
	isFound <= '0' when index_temp = 8 else '1';
	index <= index_temp;
end architecture impl;


library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.branchPredictorDeclarations.all;

entity branchPredictor is
	port (
		clk: in std_logic;
		
		-- opcode of the instruction
		opcode_atPCtoPredict: in std_logic_vector(3 downto 0);
		
		-- this is the PC of the branch which we wish to predict
		PCtoPredict: in std_logic_vector(15 downto 0);
		
		-- once the actual branch target is computed,
		-- we have to update the internal state of the branchPredictor
		-- this is the PC whose internals we want to update
		PCtoUpdate: in std_logic_vector(15 downto 0);
		
		-- the branch target that was predict and the actual branch that was taken
		branchResult: in std_logic;
		performUpdate: in std_logic;
		

		predictBranchTaken: out std_logic
		
--		DB_index: in std_logic_vector(2 downto 0);
--		DB_out: out std_logic_vector(15 downto 0)
	);
end entity branchPredictor;

architecture impl of branchPredictor is

	component branchComparator is
		port (
			PChistory: in PC_array_t;
			PCtoPredict: in std_logic_vector(15 downto 0);
			index: out integer;
			isFound: out std_logic
		);
	end component branchComparator;


	signal branchHistory: branchHistoryArray_t;
	signal MRU: std_logic_vector(7 downto 0);
	signal PChistory: PC_array_t;
	signal PCfound: std_logic;
	signal PC_index: integer;
	
	-- signals necessary for updating the BP
	signal branchHistoryNew_PCnotInHistory, branchHistoryNew_PCinHistory: branchHistoryArray_t;
	signal PChistoryNew_PCinHistory, PChistoryNew_PCnotInHistory: PC_array_t;
	signal MRUnew_PCinHistory, MRUnew_PCnotInHistory: std_logic_vector(7 downto 0);
	signal PCupdateIndex: integer;
	signal PCupdateFound: std_logic;
	signal tempPredictBranchTaken : std_logic;
begin

--	PC_index_container <= findPCindex(PChistory, PCtoPredict);
	
	predictComparator: branchComparator port map (
		PChistory => PChistory,
		PCtoPredict => PCtoPredict,
		index => PC_index,
		isFound => PCfound
	);
	
	tempPredictBranchTaken <= 	'0' when PCfound = '0' or (PC_index < 0) else	-- the check for < 0 is necessary for simulation
									'1' when (
										(branchHistory(PC_index) = StronglyTaken) or
										(branchHistory(PC_index) = WeaklyTaken)
									) else '0';
	
	predictBranchTaken <= '1' when tempPredictBranchTaken = '1' and (opcode_atPCtoPredict = "1000" or opcode_atPCtoPredict = "1001" or opcode_atPCtoPredict = "1010" or opcode_atPCtoPredict = "1100") else '0';
	
	-- logic for updating the internal states of the BP
	
	historyUpdateComparator: branchComparator port map(
		PChistory => PChistory,
		PCtoPredict => PCtoUpdate,
		index => PCupdateIndex,
		isFound => PCupdateFound
	);

	PChistoryNew_PCinHistory <= PChistory;
	
	l1: for i in 0 to 7 generate
		MRUnew_PCinHistory(i) <= '1' when PCupdateIndex = i else '0';
		branchHistoryNew_PCinHistory(i) <= 	branchHistory(i) when (not (PCupdateIndex = i)) else
														stronglyTaken when (((branchHistory(i) = stronglyTaken) or (branchHistory(i) = weaklyTaken)) and (branchResult = '1')) else
														WeaklyTaken when ((branchHistory(i) = WeaklyNotTaken and branchResult = '1') or (branchHistory(i) = StronglyTaken and branchResult = '0')) else
														WeaklyNotTaken when ((branchHistory(i) = WeaklyTaken and branchResult = '0') or (branchHistory(i) = StronglyNotTaken and branchResult = '1')) else
														StronglyNotTaken;
	end generate;
	
	MRUnew_PCnotInHistory <= "10000000";
	branchHistoryNew_PCNotInHistory(0) <= WeaklyTaken when branchResult = '1' else WeaklyNotTaken;
	PChistoryNew_PCnotInHistory(0) <= PCtoUpdate;
	l2: for i in 0 to 5 generate
		branchHistoryNew_PCnotInHistory(i+1) <= branchHistory(i);
		PChistoryNew_PCnotInHistory(i+1) <= PChistory(i);
	end generate;
	
	branchHistoryNew_PCNotInHistory(7) <= branchHistory(6) when not (MRU(7) = '1') else branchHistory(7);
	PChistoryNew_PCnotInHistory(7) <= PChistory(6) when not (MRU(7) = '1') else PChistory(7);
	
	process (clk, PCtoUpdate, branchResult) begin
		if rising_edge(clk) then
			if performUpdate = '1' then
				if PCupdateFound = '1' then
					PCHistory <= PCHistoryNew_PCinHistory;
					MRU <= MRUnew_PCinHistory;
					branchHistory <= branchHistoryNew_PCinHistory;
				else
					PCHistory <= PCHistoryNew_PCnotInHistory;
					MRU <= MRUnew_PCnotInHistory;
					branchHistory <= branchHistoryNew_PCnotInHistory;
				end if;
			end if;
		end if;
	end process;
end architecture impl;
