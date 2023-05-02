library ieee;
use iee.std_logic_1164.all;

entity branchHazardDetector is
	port (
		-- whether the branch was taken or not
		-- same as the `useNewPc` signal at the
		-- output of the execution stage
		branchTaken: in std_logic;
		
		-- the prediction made by the branch predictor
		-- note that this is the guess of the BP for that
		-- branch. so, it has to be read from the pipeline
		-- registers and not the current output of the BP
		branchPredictorGuess: in std_logic;
		
		-- whether there is a branch hazard
		branchHazard: out std_logic;
	);
end entity branchHazardDetector;

architecture impl of branchHazardDetector is
begin
	branchHazard <= '0' when (branchPredictorGuess = branchTaken) else '1';
end architecture impl;