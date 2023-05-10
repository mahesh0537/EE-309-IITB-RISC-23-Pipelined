LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY registerFileForHandler IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        regWrite : IN STD_LOGIC;
        dataIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END registerFileForHandler;

ARCHITECTURE rtl OF registerFileForHandler IS
BEGIN
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            dataOut <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF regWrite = '1' THEN
                dataOut <= dataIn;
            END IF;
        END IF;
    END PROCESS;
END rtl;

--------------------------Priority Encoder------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY priorityEncoder IS
    PORT (
        immediate : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        encoding : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        immediateOut : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        nothingLeft : OUT STD_LOGIC
    );
END priorityEncoder;

ARCHITECTURE rtl OF priorityEncoder IS
    SIGNAL tempEncoding : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tempimmediateOut : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
BEGIN
    tempEncoding <= "000" WHEN immediate(7) = '1' ELSE
        "001" WHEN immediate(6) = '1' ELSE
        "010" WHEN immediate(5) = '1' ELSE
        "011" WHEN immediate(4) = '1' ELSE
        "100" WHEN immediate(3) = '1' ELSE
        "101" WHEN immediate(2) = '1' ELSE
        "110" WHEN immediate(1) = '1' ELSE
        "111" WHEN immediate(0) = '1' ELSE
        "000";

    -- tempimmediateOut <= immediate;
    -- tempimmediateOut(to_integer(unsigned(not tempEncoding))) <= '0';
    tempimmediateOut(7) <= '0' WHEN tempEncoding = "000" ELSE
    immediate(7);
    tempimmediateOut(6) <= '0' WHEN tempEncoding = "001" ELSE
    immediate(6);
    tempimmediateOut(5) <= '0' WHEN tempEncoding = "010" ELSE
    immediate(5);
    tempimmediateOut(4) <= '0' WHEN tempEncoding = "011" ELSE
    immediate(4);
    tempimmediateOut(3) <= '0' WHEN tempEncoding = "100" ELSE
    immediate(3);
    tempimmediateOut(2) <= '0' WHEN tempEncoding = "101" ELSE
    immediate(2);
    tempimmediateOut(1) <= '0' WHEN tempEncoding = "110" ELSE
    immediate(1);
    tempimmediateOut(0) <= '0' WHEN tempEncoding = "111" ELSE
    immediate(0);
    nothingLeft <= '1' WHEN tempimmediateOut = "00000000" ELSE
        '0';
    encoding <= tempEncoding;
    immediateOut <= tempimmediateOut;

END rtl;
------------------------------Now the handler------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY LwSwHandler IS
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        gotFlushed : IN STD_LOGIC;
        instructionOut : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        keepUpdatingPC : OUT STD_LOGIC;
        useHandler : OUT STD_LOGIC
    );
END LwSwHandler;

ARCHITECTURE rtl OF LwSwHandler IS

    COMPONENT registerFileForHandler IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            regWrite : IN STD_LOGIC;
            dataIn : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT priorityEncoder IS
        PORT (
            immediate : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            encoding : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            immediateOut : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            nothingLeft : OUT STD_LOGIC
        );
    END COMPONENT;
    SIGNAL dataToRegisterFile : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL dataFromRegisterFile : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL flagGotToHandle, flagGotLMSM : STD_LOGIC;
    SIGNAL doneWithLMSM : STD_LOGIC;
    SIGNAL immediateToPE : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL encodingFromPE : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL immediateOutFromPE : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL Regi : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL XForCalcMemAdd : STD_LOGIC_VECTOR(5 DOWNTO 0) := (OTHERS => '0');

BEGIN
    registerFileForHandler1 : registerFileForHandler
    PORT MAP(
        clk => clk,
        rst => rst,
        regWrite => '1',
        dataIn => dataToRegisterFile,
        dataOut => dataFromRegisterFile
    );

    priorityEncoder1 : priorityEncoder
    PORT MAP(
        immediate => immediateToPE,
        encoding => encodingFromPE,
        immediateOut => immediateOutFromPE,
        nothingLeft => doneWithLMSM
    );
    instructionOut(15 DOWNTO 12) <= instruction(15 DOWNTO 12);
    dataToRegisterFile(15 DOWNTO 0) <= instruction;

    flagGotToHandle <= '1' WHEN instruction = dataFromRegisterFile(15 DOWNTO 0) AND (instruction(15 DOWNTO 12) = "0111" OR instruction(15 DOWNTO 12) = "0110") ELSE
        '0';
    flagGotLMSM <= '1' WHEN instruction(15 DOWNTO 12) = "0111" OR instruction(15 DOWNTO 12) = "0110" ELSE
        '0';
    keepUpdatingPC <= '1' WHEN gotFlushed = '1' OR doneWithLMSM = '1' ELSE
        NOT (flagGotToHandle OR flagGotLMSM);
    immediateToPE <= dataFromRegisterFile(23 DOWNTO 16) WHEN flagGotToHandle = '1' ELSE
        instruction(7 DOWNTO 0);
    Regi <= encodingFromPE WHEN instruction(8) = '0' ELSE
        NOT encodingFromPE;
    dataToRegisterFile(23 DOWNTO 16) <= immediateOutFromPE;
    instructionOut(11 DOWNTO 9) <= Regi;
    XForCalcMemAdd <= "000000" WHEN ((flagGotToHandle XOR flagGotLMSM) = '1') OR ((flagGotToHandle OR flagGotLMSM) = '0') ELSE
        STD_LOGIC_VECTOR(unsigned(dataFromRegisterFile(29 DOWNTO 24)) + 1 + 1);
    dataToRegisterFile(29 DOWNTO 24) <= XForCalcMemAdd;
    instructionOut(5 DOWNTO 0) <= XForCalcMemAdd;
    instructionOut(8 DOWNTO 6) <= instruction(11 DOWNTO 9);
    useHandler <= NOT (flagGotToHandle OR flagGotLMSM);
END rtl;