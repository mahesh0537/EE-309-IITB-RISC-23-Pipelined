library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dataTypeConverter.all;

entity IF_ID_Reg is
end entity IF_ID_Reg;

architecture whatever of IF_ID_Reg is
    --Component
    component instructionFetch is
        port(
        clk : in std_logic;
        PCtoFetch : in std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(15 downto 0);
        PCfromEx : in std_logic_vector(15 downto 0);
        PCbranchSignal_Ex : in std_logic;
        PCOutFinal : out std_logic_vector(15 downto 0)
    );
    end component;

    component instructionDecoder is 
    port(
		instruction: in std_logic_vector(15 downto 0);
		Ra, Rb, Rc: out std_logic_vector(2 downto 0);
		immediate: out std_logic_vector(15 downto 0);
		condition: out std_logic_vector(1 downto 0);
		useComplement: out std_logic;
		opcode: out std_logic_vector(3 downto 0)
    );
    end component;

    component regFile is
        port(
        clk : in std_logic;
        regWrite : in std_logic;
        reg1Addr, reg2Addr, reg3Addr : in std_logic_vector(2 downto 0);
        reg1Data, reg2Data, PC : out std_logic_vector(15 downto 0);
        reg3Data, PCtoRF : in std_logic_vector(15 downto 0);
        reset : in std_logic;
        updatePC : in std_logic;
        readPC : in std_logic   --toggle to read PC, anytime
    );
    end component;

    component execStage is
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
            
            stallInstructionRead: out std_logic
        );
    end component;

    component memory is
        port(
        RAM_Address : in std_logic_vector(15 downto 0); -- 16 bit address for read/write
        RAM_Data_IN : in std_logic_vector(15 downto 0); -- 16 bit data for write
        RAM_Data_OUT : out std_logic_vector(15 downto 0); -- 16 bit data for read
        RAM_Write : in std_logic; -- write enable
        RAM_Clock : in std_logic -- clock
    );
    end component;

    component writeBack is
        port(
            clk : in std_logic;
            writeSignal : in std_logic;
            writeSignalOut : out std_logic;
            selectSignalEx_RAM : in std_logic;
            writeDataIN_Ex : in std_logic_vector(15 downto 0);
            writeDataIN_RAM : in std_logic_vector(15 downto 0);
            writeDataOUT : out std_logic_vector(15 downto 0);
            writeAddressIN : in std_logic_vector(2 downto 0);
            writeAddressOUT : out std_logic_vector(2 downto 0)
        );
    end component;

    component flagReg is
        port (
            clk, reset : in std_logic;
            SetZ : in std_logic;
            Z : out std_logic;
            SetC : in std_logic;
            C : out std_logic
        );
    end component;



    --Signals
    signal clk : std_logic := '0';
    signal PCtoFetch : std_logic_vector(15 downto 0) := (others => '0');
    signal instruction_IF : std_logic_vector(15 downto 0) := (others => '0');
    signal PCfrom_Ex : std_logic_vector(15 downto 0) := (others => '0');
    signal PCbranchSignal_Ex : std_logic := '0';
    signal PCOutFinal_IF : std_logic_vector(15 downto 0) := (others => '0');
    signal testvar : std_logic_vector(15 downto 0) := (others => '0');

    --Signal for Instruction Decoder
    signal Ra_ID, Rb_ID, Rc_ID : std_logic_vector(2 downto 0) := (others => '0');
    signal immediate_ID : std_logic_vector(15 downto 0) := (others => '0');
    signal condition_ID : std_logic_vector(1 downto 0) := (others => '0');
    signal useComplement_ID : std_logic := '0';
    signal opcode_ID : std_logic_vector(3 downto 0) := (others => '0');

    --Signal for Register File
    signal reg1Data_RF, reg2Data_RF, PC_RF : std_logic_vector(15 downto 0) := (others => '0');
    signal regResetSignal : std_logic := '0';
    signal updatePCinRegFile : std_logic := '0';


    --Signal for Exec
    signal reg3Data_Ex : std_logic_vector(15 downto 0) := (others => '0');
    signal reg3Addr_Ex : std_logic_vector(2 downto 0) := (others => '0');
    signal RAM_Address_Ex : std_logic_vector(15 downto 0) := (others => '0');
    signal RAM_writeEnable_Ex : std_logic := '0';
    signal RAM_DataToWrite_Ex : std_logic_vector(15 downto 0) := (others => '0');
    signal writeBackUseRAM_orALU_Ex : std_logic := '0';
    signal writeBackEnable_Ex : std_logic := '0';
    signal stallInstructionRead_Ex : std_logic := '0';

    --Signal for MEM
    signal RAM_Data_OUT_MEM : std_logic_vector(15 downto 0) := (others => '0');

    --Signal for WB
    signal regWriteEnable_WB : std_logic := '1';
    signal reg3Addr_WB : std_logic_vector(2 downto 0) := (others => '1');
    signal reg3Data_WB : std_logic_vector(15 downto 0) := (others => '1');

    --Signal for FlagReg
    signal Z_Ex, C_Ex : std_logic := '0';
    signal Z_FlagReg, C_FlagReg : std_logic := '0';
    signal resetFlags : std_logic := '0';


    signal randomSignal : std_logic := '0';



begin
    flagReg1 : flagReg port map(
        clk => clk, reset => resetFlags,
        SetZ => Z_Ex, Z => Z_FlagReg,
        SetC => C_Ex, C => C_FlagReg
    );
    instructionFetch1 : instructionFetch port map(
        clk => clk,
        PCtoFetch => PC_RF,
        instruction => instruction_IF,
        PCfromEx => PCfrom_Ex,
        PCbranchSignal_Ex => PCbranchSignal_Ex,
        PCOutFinal => PCOutFinal_IF
    );
    instructionDecode1 : instructionDecoder port map(
        instruction => instruction_IF,
        Ra => Ra_ID, Rb => Rb_ID, Rc => Rc_ID,
        immediate => immediate_ID, condition => condition_ID,
        useComplement => useComplement_ID,
        opcode => opcode_ID
    );
    regFile1 : regFile port map(
        clk => clk,
        regWrite => regWriteEnable_WB,
        reg1Addr => Ra_ID, reg2Addr => Rb_ID, reg3Addr => reg3Addr_WB,
        reg1Data => reg1Data_RF, reg2Data => reg2Data_RF, reg3Data => reg3Data_WB,
        PC => PC_RF, PCtoRF => PCOutFinal_IF,
        reset => regResetSignal, updatePC => updatePCinRegFile, readPC => '1'
    );
    execStage1 : execStage port map(
        opcode => opcode_ID,
        Ra => Ra_ID, Rb => Rb_ID, Rc => Rc_ID,
        RaValue => reg1Data_RF, RbValue => reg2Data_RF,
        immediate => immediate_ID, condition => condition_ID,
        useComplement => useComplement_ID,
        PC => PC_RF,
        PC_new => PCfrom_Ex,
        useNewPc => PCbranchSignal_Ex,
        regNewValue => reg3Data_Ex,
        regToWrite => reg3Addr_Ex,
        writeReg => randomSignal,
        zeroFlagIn => Z_FlagReg, zeroFlagOut => Z_Ex,
        carryFlagIn => C_FlagReg, carryFlagOut => C_Ex,
        RAM_Address => RAM_Address_Ex,
        RAM_writeEnable => RAM_writeEnable_Ex,
        RAM_DataToWrite => RAM_DataToWrite_Ex,
        writeBackUseRAM_orALU => writeBackUseRAM_orALU_Ex,
        writeBackEnable => writeBackEnable_Ex,
        stallInstructionRead => stallInstructionRead_Ex
    );
    RAM1 : memory port map(
        RAM_Address => RAM_Address_Ex,
        RAM_Data_IN => RAM_DataToWrite_Ex,
        RAM_Data_OUT => RAM_Data_OUT_MEM,
        RAM_Write => RAM_writeEnable_Ex,
        RAM_Clock => clk
    );

    writeBack1 : writeBack port map(
        clk => clk,
        writeSignal => writeBackEnable_Ex,
        writeSignalOut => regWriteEnable_WB,
        selectSignalEx_RAM => writeBackUseRAM_orALU_Ex,
        writeDataIN_Ex => reg3Data_Ex,
        writeDataIN_RAM => RAM_Data_OUT_MEM,
        writeDataOUT => reg3Data_WB,
        writeAddressIN => reg3Addr_Ex,
        writeAddressOUT => reg3Addr_WB
    );
    
    process
    variable OUTPUT_LINE: line;
    variable LINE_COUNT: integer := 0;
    variable i : integer := 0;
    File OUTFILE: text open write_mode is "testBench/IF_ID_RegTB.out";

    begin
        while i < 10 loop
            clk <= not clk;
            wait for 40 ns;
            i := i + 1;
            -- PCtoFetch <= PCOutFinal_IF;
            updatePCinRegFile <= not stallInstructionRead_Ex;
            --IF WRITE
            write(OUTPUT_LINE, to_string(" ______________________________________________________ "));
            writeline(OUTFILE, OUTPUT_LINE);
            write(OUTPUT_LINE, to_string(" CLOCK: "));
            write(OUTPUT_LINE, std_logic_to_bit(clk));
            writeline(OUTFILE, OUTPUT_LINE);
            write(OUTPUT_LINE, to_string("Instruction: "));
            write(OUTPUT_LINE, to_bitvector(instruction_IF));
            write(OUTPUT_LINE, to_string(" PCtoFetch: "));
            write(OUTPUT_LINE, to_bitvector(PCtoFetch));
            write(OUTPUT_LINE, to_string(" PCOUT: "));
            write(OUTPUT_LINE, to_bitvector(PCOutFinal_IF));
            writeline(OUTFILE, OUTPUT_LINE);

            --ID WRITE
            write(OUTPUT_LINE, to_string("Ra: "));
            write(OUTPUT_LINE, to_bitvector(Ra_ID));
            write(OUTPUT_LINE, to_string(" Rb: "));
            write(OUTPUT_LINE, to_bitvector(Rb_ID));
            write(OUTPUT_LINE, to_string(" Rc: "));
            write(OUTPUT_LINE, to_bitvector(Rc_ID));
            write(OUTPUT_LINE, to_string(" immediate: "));
            write(OUTPUT_LINE, to_bitvector(immediate_ID));
            write(OUTPUT_LINE, to_string(" condition: "));
            write(OUTPUT_LINE, to_bitvector(condition_ID));
            write(OUTPUT_LINE, to_string(" useComplement: "));
            write(OUTPUT_LINE, std_logic_to_bit(useComplement_ID));
            write(OUTPUT_LINE, to_string(" opcode: "));
            write(OUTPUT_LINE, to_bitvector(opcode_ID));
            writeline(OUTFILE, OUTPUT_LINE);

            --RF WRITE
            write(OUTPUT_LINE, to_string("reg1Data: "));
            write(OUTPUT_LINE, to_bitvector(reg1Data_RF));
            write(OUTPUT_LINE, to_string(" reg2Data: "));
            write(OUTPUT_LINE, to_bitvector(reg2Data_RF));
            write(OUTPUT_LINE, to_string(" PC: "));
            write(OUTPUT_LINE, to_bitvector(PC_RF));
            writeline(OUTFILE, OUTPUT_LINE);

            --EX WRITE
            write(OUTPUT_LINE, to_string("PCfrom_Ex: "));
            write(OUTPUT_LINE, to_bitvector(PCfrom_Ex));
            write(OUTPUT_LINE, to_string(" PCbranchSignal_Ex: "));
            write(OUTPUT_LINE, std_logic_to_bit(PCbranchSignal_Ex));
            write(OUTPUT_LINE, to_string(" reg3Data_Ex: "));
            write(OUTPUT_LINE, to_bitvector(reg3Data_Ex));
            write(OUTPUT_LINE, to_string(" reg3Addr_Ex: "));
            write(OUTPUT_LINE, to_bitvector(reg3Addr_Ex));
            write(OUTPUT_LINE, to_string(" RAM_Address_Ex: "));
            write(OUTPUT_LINE, to_bitvector(RAM_Address_Ex));
            write(OUTPUT_LINE, to_string(" RAM_writeEnable_Ex: "));
            write(OUTPUT_LINE, std_logic_to_bit(RAM_writeEnable_Ex));
            write(OUTPUT_LINE, to_string(" RAM_DataToWrite_Ex: "));
            write(OUTPUT_LINE, to_bitvector(RAM_DataToWrite_Ex));
            write(OUTPUT_LINE, to_string(" writeBackUseRAM_orALU_Ex: "));
            write(OUTPUT_LINE, std_logic_to_bit(writeBackUseRAM_orALU_Ex));
            write(OUTPUT_LINE, to_string(" writeBackEnable_Ex: "));
            write(OUTPUT_LINE, std_logic_to_bit(writeBackEnable_Ex));
            write(OUTPUT_LINE, to_string(" stallInstructionRead_Ex: "));
            write(OUTPUT_LINE, std_logic_to_bit(stallInstructionRead_Ex));
            writeline(OUTFILE, OUTPUT_LINE);

            --MEM WRITE
            write(OUTPUT_LINE, to_string("RAM_Address_Ex: "));
            write(OUTPUT_LINE, to_bitvector(RAM_Address_Ex));
            write(OUTPUT_LINE, to_string(" RAM_DataToWrite_Ex: "));
            write(OUTPUT_LINE, to_bitvector(RAM_DataToWrite_Ex));
            write(OUTPUT_LINE, to_string(" RAM_writeEnable_Ex: "));
            write(OUTPUT_LINE, std_logic_to_bit(RAM_writeEnable_Ex));
            write(OUTPUT_LINE, to_string(" RAM_Data_OUT_MEM: "));
            write(OUTPUT_LINE, to_bitvector(RAM_Data_OUT_MEM));
            writeline(OUTFILE, OUTPUT_LINE);

            --WB WRITE
            write(OUTPUT_LINE, to_string("reg3Data_WB: "));
            write(OUTPUT_LINE, to_bitvector(reg3Data_WB));
            write(OUTPUT_LINE, to_string(" reg3Addr_WB: "));
            write(OUTPUT_LINE, to_bitvector(reg3Addr_WB));
            write(OUTPUT_LINE, to_string(" writeBackEnable_WB: "));
            write(OUTPUT_LINE, std_logic_to_bit(regWriteEnable_WB));
            writeline(OUTFILE, OUTPUT_LINE);
            clk <= not clk;
            wait for 40 ns;
        end loop;
    end process;
end whatever;