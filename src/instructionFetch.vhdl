LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY instructionFetch IS
    PORT (
        clk : IN STD_LOGIC;
        PCtoFetch : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        instruction : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        PCfromEx : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        PCbranchSignal_Ex : IN STD_LOGIC;
        PCOutFinal : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        GotBubbled : IN STD_LOGIC
    );
END ENTITY;

ARCHITECTURE impl OF instructionFetch IS
    COMPONENT instructionMemory IS
        PORT (
            clk : IN STD_LOGIC;
            address : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            instruction : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT mux2 IS
        PORT (
            data0, data1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            sel : IN STD_LOGIC;
            data_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT LwSwHandler IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            gotFlushed : IN STD_LOGIC;
            instructionOut : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

            keepUpdatingPC : OUT STD_LOGIC;
            useHandler : OUT STD_LOGIC
        );
    END COMPONENT;
    SIGNAL PCnormalUpdate : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL signalFromHandler, signalFromHandlerForPC : STD_LOGIC := '0';
    SIGNAL instructionFromMen : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL instructionFromHandler : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN
    memory1 : instructionMemory PORT MAP(
        clk => clk,
        address => PCnormalUpdate,
        instruction => instructionFromMen
    );
    mux2PC : mux2 PORT MAP(
        data0 => PCtoFetch,
        data1 => PCfromEx,
        sel => PCbranchSignal_Ex,
        data_out => PCnormalUpdate
    );
    LwSwHandler1 : LwSwHandler PORT MAP(
        clk => clk,
        rst => '0',
        instruction => instructionFromMen,
        gotFlushed => PCbranchSignal_Ex,
        instructionOut => instructionFromHandler,
        keepUpdatingPC => signalFromHandler,
        useHandler => signalFromHandlerForPC
    );
    instruction <= instructionFromHandler WHEN signalFromHandlerForPC = '0' ELSE
        instructionFromMen;
    PCOutFinal <= STD_LOGIC_VECTOR(unsigned(PCnormalUpdate) + 2) WHEN (GotBubbled = '0' AND signalFromHandler = '1') ELSE
        PCnormalUpdate;
END impl;