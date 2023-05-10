LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- we need an extra adder to precompute the branch targets
ENTITY branchPredictorALU IS
    PORT (
        opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        PC, imm : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        branchPredictor_prediction : IN STD_LOGIC;

        branchTarget : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ENTITY branchPredictorALU;

ARCHITECTURE impl OF branchPredictorALU IS
    SIGNAL adderA, adderB : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL immTimes2 : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN
    -- left shift by 1 is same as multiplying by 2
    immTimes2 <= imm(14 DOWNTO 0) & '0';
    adderA <= PC;

    WITH opcode & branchPredictor_prediction SELECT
    adderB <=
        immTimes2 WHEN
        "1000" & '1' |
        "1001" & '1' |
        "1010" & '1' |
        "1100" & '1',
        "0000000000000010" WHEN OTHERS;

    branchTarget <= STD_LOGIC_VECTOR(unsigned(adderA) + unsigned(adderB));

END ARCHITECTURE impl;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE branchPredictorDeclarations IS
    TYPE branchHistory IS (StronglyTaken, WeaklyTaken, WeaklyNotTaken, StronglyNotTaken);
    TYPE PC_array_t IS ARRAY(0 TO 7) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    TYPE branchHistoryArray_t IS ARRAY(0 TO 7) OF branchHistory;
END PACKAGE branchPredictorDeclarations;
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY work;
USE work.branchPredictorDeclarations.ALL;

ENTITY branchComparator IS
    PORT (
        PChistory : IN PC_array_t;
        PCtoPredict : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        index : OUT INTEGER;
        isFound : OUT STD_LOGIC
    );
END ENTITY branchComparator;

ARCHITECTURE impl OF branchComparator IS
    SIGNAL index_temp : INTEGER;
BEGIN
    index_temp <= 0 WHEN PChistory(0) = PCtoPredict ELSE
        1 WHEN PChistory(1) = PCtoPredict ELSE
        2 WHEN PChistory(2) = PCtoPredict ELSE
        3 WHEN PChistory(3) = PCtoPredict ELSE
        4 WHEN PChistory(4) = PCtoPredict ELSE
        5 WHEN PChistory(5) = PCtoPredict ELSE
        6 WHEN PChistory(6) = PCtoPredict ELSE
        7 WHEN PChistory(7) = PCtoPredict ELSE
        8;

    isFound <= '0' WHEN index_temp = 8 ELSE
        '1';
    index <= index_temp;
END ARCHITECTURE impl;
LIBRARY ieee;
LIBRARY work;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.branchPredictorDeclarations.ALL;

ENTITY branchPredictor IS
    PORT (
        clk : IN STD_LOGIC;

        -- opcode of the instruction
        opcode_atPCtoPredict : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

        -- this is the PC of the branch which we wish to predict
        PCtoPredict : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- once the actual branch target is computed,
        -- we have to update the internal state of the branchPredictor
        -- this is the PC whose internals we want to update
        PCtoUpdate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        -- the branch target that was predict and the actual branch that was taken
        branchResult : IN STD_LOGIC;
        performUpdate : IN STD_LOGIC;
        predictBranchTaken : OUT STD_LOGIC

        --		DB_index: in std_logic_vector(2 downto 0);
        --		DB_out: out std_logic_vector(15 downto 0)
    );
END ENTITY branchPredictor;

ARCHITECTURE impl OF branchPredictor IS

    COMPONENT branchComparator IS
        PORT (
            PChistory : IN PC_array_t;
            PCtoPredict : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            index : OUT INTEGER;
            isFound : OUT STD_LOGIC
        );
    END COMPONENT branchComparator;
    SIGNAL branchHistory : branchHistoryArray_t;
    SIGNAL MRU : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL PChistory : PC_array_t;
    SIGNAL PCfound : STD_LOGIC;
    SIGNAL PC_index : INTEGER;

    -- signals necessary for updating the BP
    SIGNAL branchHistoryNew_PCnotInHistory, branchHistoryNew_PCinHistory : branchHistoryArray_t;
    SIGNAL PChistoryNew_PCinHistory, PChistoryNew_PCnotInHistory : PC_array_t;
    SIGNAL MRUnew_PCinHistory, MRUnew_PCnotInHistory : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL PCupdateIndex : INTEGER;
    SIGNAL PCupdateFound : STD_LOGIC;
    SIGNAL tempPredictBranchTaken : STD_LOGIC;
BEGIN

    --	PC_index_container <= findPCindex(PChistory, PCtoPredict);

    predictComparator : branchComparator PORT MAP(
        PChistory => PChistory,
        PCtoPredict => PCtoPredict,
        index => PC_index,
        isFound => PCfound
    );

    tempPredictBranchTaken <= '0' WHEN PCfound = '0' OR (PC_index < 0) ELSE -- the check for < 0 is necessary for simulation
        '1' WHEN (
        (branchHistory(PC_index) = StronglyTaken) OR
        (branchHistory(PC_index) = WeaklyTaken)
        ) ELSE
        '0';

    predictBranchTaken <= '1' WHEN tempPredictBranchTaken = '1' AND (opcode_atPCtoPredict = "1000" OR opcode_atPCtoPredict = "1001" OR opcode_atPCtoPredict = "1010" OR opcode_atPCtoPredict = "1100") ELSE
        '0';

    -- logic for updating the internal states of the BP

    historyUpdateComparator : branchComparator PORT MAP(
        PChistory => PChistory,
        PCtoPredict => PCtoUpdate,
        index => PCupdateIndex,
        isFound => PCupdateFound
    );

    PChistoryNew_PCinHistory <= PChistory;

    l1 : FOR i IN 0 TO 7 GENERATE
        MRUnew_PCinHistory(i) <= '1' WHEN PCupdateIndex = i ELSE
        '0';
        branchHistoryNew_PCinHistory(i) <= branchHistory(i) WHEN (NOT (PCupdateIndex = i)) ELSE
        stronglyTaken WHEN (((branchHistory(i) = stronglyTaken) OR (branchHistory(i) = weaklyTaken)) AND (branchResult = '1')) ELSE
        WeaklyTaken WHEN ((branchHistory(i) = WeaklyNotTaken AND branchResult = '1') OR (branchHistory(i) = StronglyTaken AND branchResult = '0')) ELSE
        WeaklyNotTaken WHEN ((branchHistory(i) = WeaklyTaken AND branchResult = '0') OR (branchHistory(i) = StronglyNotTaken AND branchResult = '1')) ELSE
        StronglyNotTaken;
    END GENERATE;

    MRUnew_PCnotInHistory <= "10000000";
    branchHistoryNew_PCNotInHistory(0) <= WeaklyTaken WHEN branchResult = '1' ELSE
    WeaklyNotTaken;
    PChistoryNew_PCnotInHistory(0) <= PCtoUpdate;
    l2 : FOR i IN 0 TO 5 GENERATE
        branchHistoryNew_PCnotInHistory(i + 1) <= branchHistory(i);
        PChistoryNew_PCnotInHistory(i + 1) <= PChistory(i);
    END GENERATE;

    branchHistoryNew_PCNotInHistory(7) <= branchHistory(6) WHEN NOT (MRU(7) = '1') ELSE
    branchHistory(7);
    PChistoryNew_PCnotInHistory(7) <= PChistory(6) WHEN NOT (MRU(7) = '1') ELSE
    PChistory(7);

    PROCESS (clk, PCtoUpdate, branchResult) BEGIN
        IF rising_edge(clk) THEN
            IF performUpdate = '1' THEN
                IF PCupdateFound = '1' THEN
                    PCHistory <= PCHistoryNew_PCinHistory;
                    MRU <= MRUnew_PCinHistory;
                    branchHistory <= branchHistoryNew_PCinHistory;
                ELSE
                    PCHistory <= PCHistoryNew_PCnotInHistory;
                    MRU <= MRUnew_PCnotInHistory;
                    branchHistory <= branchHistoryNew_PCnotInHistory;
                END IF;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE impl;