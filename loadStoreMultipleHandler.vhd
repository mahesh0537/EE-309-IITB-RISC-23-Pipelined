library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registerFileForHandler is
    port(
        clk : in std_logic;
        rst : in std_logic;
        regWrite : in std_logic;
        dataIn : in std_logic_vector(31 downto 0);
        dataOut : out std_logic_vector(31 downto 0)
    );
end registerFileForHandler;

architecture rtl of registerFileForHandler is
begin
    process(clk, rst)
    begin
        if rst = '1' then
            dataOut <= (others => '0');
        elsif rising_edge(clk) then
            if regWrite = '1' then
                dataOut <= dataIn;
            end if;
        end if;
    end process;
end rtl;

--------------------------Priority Encoder------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity priorityEncoder is
    port(
        immediate : in std_logic_vector(7 downto 0);
        encoding : out std_logic_vector(2 downto 0);
        immediateOut : out std_logic_vector(7 downto 0);
        nothingLeft : out std_logic
    );
end priorityEncoder;

architecture rtl of priorityEncoder is
signal tempEncoding : std_logic_vector(2 downto 0) := (others => '0');
signal tempimmediateOut : std_logic_vector(7 downto 0) := (others => '0');
begin
    tempEncoding <= "000" when immediate(7) = '1' else
                "001" when immediate(6) = '1' else
                "010" when immediate(5) = '1' else
                "011" when immediate(4) = '1' else
                "100" when immediate(3) = '1' else
                "101" when immediate(2) = '1' else
                "110" when immediate(1) = '1' else
                "111" when immediate(0) = '1' else
                "000";
    
    -- tempimmediateOut <= immediate;
    -- tempimmediateOut(to_integer(unsigned(not tempEncoding))) <= '0';
    tempimmediateOut(7) <= '0' when tempEncoding = "000" else immediate(7);
    tempimmediateOut(6) <= '0' when tempEncoding = "001" else immediate(6);
    tempimmediateOut(5) <= '0' when tempEncoding = "010" else immediate(5);
    tempimmediateOut(4) <= '0' when tempEncoding = "011" else immediate(4);
    tempimmediateOut(3) <= '0' when tempEncoding = "100" else immediate(3);
    tempimmediateOut(2) <= '0' when tempEncoding = "101" else immediate(2);
    tempimmediateOut(1) <= '0' when tempEncoding = "110" else immediate(1);
    tempimmediateOut(0) <= '0' when tempEncoding = "111" else immediate(0);
    nothingLeft <= '1' when tempimmediateOut = "00000000" else '0';
    encoding <= tempEncoding;
    immediateOut <= tempimmediateOut;

end rtl;


------------------------------Now the handler------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LwSwHandler is
    port(
        clk : in std_logic;
        rst : in std_logic;
        instruction : in std_logic_vector(15 downto 0);
        gotFlushed : in std_logic;
        instructionOut : out std_logic_vector(15 downto 0);

        keepUpdatingPC : out std_logic;
        useHandler : out std_logic
    );
end LwSwHandler;

architecture rtl of LwSwHandler is

    component registerFileForHandler is
        port(
            clk : in std_logic;
            rst : in std_logic;
            regWrite : in std_logic;
            dataIn : in std_logic_vector(31 downto 0);
            dataOut : out std_logic_vector(31 downto 0)
        );
    end component;

    component priorityEncoder is
        port(
            immediate : in std_logic_vector(7 downto 0);
            encoding : out std_logic_vector(2 downto 0);
            immediateOut : out std_logic_vector(7 downto 0);
            nothingLeft : out std_logic
        );
    end component;
    signal dataToRegisterFile : std_logic_vector(31 downto 0);
    signal dataFromRegisterFile : std_logic_vector(31 downto 0);
    signal flagGotToHandle, flagGotLMSM : std_logic;
    signal doneWithLMSM : std_logic;
    signal immediateToPE : std_logic_vector(7 downto 0);
    signal encodingFromPE : std_logic_vector(2 downto 0);
    signal immediateOutFromPE : std_logic_vector(7 downto 0);
    signal Regi : std_logic_vector(2 downto 0);
    signal XForCalcMemAdd : std_logic_vector(5 downto 0):= (others => '0');

begin
    registerFileForHandler1 : registerFileForHandler
        port map(
            clk => clk,
            rst => rst,
            regWrite => '1',
            dataIn => dataToRegisterFile,
            dataOut => dataFromRegisterFile
        );

    priorityEncoder1 : priorityEncoder
    port map(
        immediate => immediateToPE,
        encoding => encodingFromPE,
        immediateOut => immediateOutFromPE,
        nothingLeft => doneWithLMSM
    );
    instructionOut(15 downto 12) <= instruction(15 downto 12);
    dataToRegisterFile(15 downto 0) <= instruction;

    flagGotToHandle <= '1' when instruction = dataFromRegisterFile(15 downto 0) and (instruction(15 downto 12) = "0111" or instruction(15 downto 12) ="0110") else '0';
    flagGotLMSM <= '1' when instruction(15 downto 12) = "0111" or instruction(15 downto 12) ="0110" else '0';
    keepUpdatingPC <= '1' when gotFlushed = '1' or doneWithLMSM = '1' else not (flagGotToHandle or flagGotLMSM);
    immediateToPE <= dataFromRegisterFile(23 downto 16) when flagGotToHandle = '1' else instruction(7 downto 0);
    Regi <= encodingFromPE when instruction(8) = '0' else not encodingFromPE;
    dataToRegisterFile(23 downto 16) <= immediateOutFromPE;
    instructionOut(11 downto 9) <= Regi;
    XForCalcMemAdd <= "000000" when ((flagGotToHandle xor flagGotLMSM) = '1') or ((flagGotToHandle or flagGotLMSM) = '0') else std_logic_vector(unsigned(dataFromRegisterFile(29 downto 24)) + 1 + 1); 
    dataToRegisterFile(29 downto 24) <= XForCalcMemAdd;
    instructionOut(5 downto 0) <= XForCalcMemAdd;
    instructionOut(8 downto 6) <= instruction(11 downto 9);
    useHandler <= not (flagGotToHandle or flagGotLMSM);
    end rtl;


    