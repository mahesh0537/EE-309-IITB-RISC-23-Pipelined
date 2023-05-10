LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY branchHazardDetector IS
    PORT (
        -- whether the branch was taken or not
        -- same as the `useNewPc` signal at the
        -- output of the execution stage
        branchTaken : IN STD_LOGIC;

        -- the prediction made by the branch predictor
        -- note that this is the guess of the BP for that
        -- branch. so, it has to be read from the pipeline
        -- registers and not the current output of the BP
        branchPredictorGuess : IN STD_LOGIC;

        -- whether there is a branch hazard
        branchHazard : OUT STD_LOGIC
    );
END ENTITY branchHazardDetector;

ARCHITECTURE impl OF branchHazardDetector IS
BEGIN
    branchHazard <= '0' WHEN (branchPredictorGuess = branchTaken) ELSE
        '1';
END ARCHITECTURE impl;