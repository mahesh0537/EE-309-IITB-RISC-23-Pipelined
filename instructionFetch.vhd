library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instructionFetch is
    port(
        clk : in std_logic;
        PCtoFetch : in std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(15 downto 0);
        PCfromEx : in std_logic_vector(15 downto 0);
        PCbranchSignal_Ex : in std_logic;
        PCOutFinal : out std_logic_vector(15 downto 0);
        GotBubbled : in std_logic
    );
end entity;

architecture impl of instructionFetch is
    component instructionMemory is
        port(
            clk : in std_logic;
            address : in std_logic_vector(15 downto 0);
            instruction : out std_logic_vector(15 downto 0)
        );
    end component;

    component mux2 is
        port(
            data0, data1 : in std_logic_vector(15 downto 0);
            sel : in std_logic;
            data_out : out std_logic_vector(15 downto 0)
        );
    end component;

    component LwSwHandler is
        port(
            clk : in std_logic;
            rst : in std_logic;
            instruction : in std_logic_vector(15 downto 0);
            gotFlushed : in std_logic;
            instructionOut : out std_logic_vector(15 downto 0);
    
            keepUpdatingPC : out std_logic;
            useHandler : out std_logic
        );
    end component;
    signal PCnormalUpdate : std_logic_vector(15 downto 0);
    signal signalFromHandler, signalFromHandlerForPC : std_logic := '0';
    signal instructionFromMen : std_logic_vector(15 downto 0);
    signal instructionFromHandler : std_logic_vector(15 downto 0);

begin
    memory1 : instructionMemory port map(
        clk => clk,
        address => PCtoFetch,
        instruction => instructionFromMen
    );
    mux2PC : mux2 port map(
        data0 => PCnormalUpdate,
        data1 => PCfromEx,
        sel => PCbranchSignal_Ex,
        data_out => PCOutFinal
    );
    LwSwHandler1 : LwSwHandler port map(
        clk => clk,
        rst => '0',
        instruction => instructionFromMen,
        gotFlushed => PCbranchSignal_Ex,
        instructionOut => instructionFromHandler,
        keepUpdatingPC => signalFromHandler,
        useHandler =>signalFromHandlerForPC
    );
    instruction <= instructionFromHandler when signalFromHandlerForPC = '0' else instructionFromMen;
    PCnormalUpdate <= std_logic_vector(unsigned(PCtoFetch) + 2) when (GotBubbled = '0' and signalFromHandler = '1')  else PCtoFetch;
end impl;