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
        PCOutFinal : out std_logic_vector(15 downto 0)
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
    signal PCnormalUpdate : std_logic_vector(15 downto 0);

begin
    memory1 : instructionMemory port map(
        clk => clk,
        address => PCtoFetch,
        instruction => instruction
    );
    mux2PC : mux2 port map(
        data0 => PCnormalUpdate,
        data1 => PCfromEx,
        sel => PCbranchSignal_Ex,
        data_out => PCOutFinal
    );
    PCnormalUpdate <= std_logic_vector(unsigned(PCtoFetch) + 2);
end impl;