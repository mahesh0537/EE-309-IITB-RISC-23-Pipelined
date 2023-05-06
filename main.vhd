library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dataTypeConverter.all;

entity pipelineDataPath is
end entity pipelineDataPath;

architecture whatever of pipelineDataPath is
    --Component
    component instructionFetch is
        port(
        clk : in std_logic;
        PCtoFetch : in std_logic_vector(15 downto 0);
        instruction : out std_logic_vector(15 downto 0);
        PCfromEx : in std_logic_vector(15 downto 0);
        PCbranchSignal_Ex : in std_logic;
        PCOutFinal : out std_logic_vector(15 downto 0);
        GotBubbled : in std_logic
    );
    end component;

    component dataForwarder is
        port(
            -- the opcode of the instruction that is going to be executed
            currentOpcode: in std_logic_vector(3 downto 0);
            
            -- the two inputs to the execute stage
            currentRegisterA: in std_logic_vector(2 downto 0);
            currentRegisterAValue: in std_logic_vector(15 downto 0);
            currentRegisterB: in std_logic_vector(2 downto 0);
            currentRegisterBValue: in std_logic_vector(15 downto 0);
            
            execute_RegToWrite: in std_logic_vector(2 downto 0);
            execute_WriteEnable: in std_logic;
            execute_RegValue: in std_logic_vector(15 downto 0);
            execute_opcode: in std_logic_vector(3 downto 0);
            mem_RegToWrite: in std_logic_vector(2 downto 0);
            mem_WriteEnable: in std_logic;
            mem_RegValue: in std_logic_vector(15 downto 0);
            mem_opcode: in std_logic_vector(3 downto 0);
            writeBack_RegToWrite: in std_logic_vector(2 downto 0);
            writeBack_WriteEnable: in std_logic;
            writeBack_RegValue: in std_logic_vector(15 downto 0);
            writeBack_opcode: in std_logic_vector(3 downto 0);
            
            dataToUseAfterAccountingHazardsRegA: out std_logic_vector(15 downto 0);
            dataToUseAfterAccountingHazardsRegB: out std_logic_vector(15 downto 0);
            
            insertBubbleInPipeline: out std_logic
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
            
            stallInstructionRead: out std_logic;
            beenFlushed: in std_logic
        );
    end component;

    component dataMemory is
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
            writeAddressOUT : out std_logic_vector(2 downto 0);
            GotFlushed : in std_logic
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

    component NBitRegister is
        generic (
            N: integer;
            default: std_logic := '0'
        );
        port (
            dataIn: in std_logic_vector(N-1 downto 0);
            writeEnable: in std_logic;
            clk: in std_logic;
            asyncReset: in std_logic;
            dataOut: out std_logic_vector(N-1 downto 0)
        );
    end component;

    component branchPredictor is
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
    end component;


    component branchPredictorALU is
        port (
            opcode: in std_logic_vector(3 downto 0);
            PC, imm: in std_logic_vector(15 downto 0);
            branchPredictor_prediction: in std_logic;
            
            branchTarget: out std_logic_vector(15 downto 0)
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


    -- signal randomSignal : std_logic := '0';


    --Signals for Pipeline Registers
    signal FetchToDecodeDataIn, FetchToDecodeDataOut : std_logic_vector(47 downto 0) := (others => '0');
    signal DecodeToRegFileDataIn, DecodeToRegFileDataOut : std_logic_vector(49 downto 0) := (others => '0');
    signal RegFileToExecDataIn, RegFileToExecDataOut : std_logic_vector(81 downto 0) := (others => '0');
    signal ExecToMemDataIn, ExecToMemDataOut : std_logic_vector(61 downto 0) := (others => '0');
    signal MemToWBDataIn, MemToWBDataOut : std_logic_vector(43 downto 0) := (others => '0');
    signal GotBubbled : std_logic := '0';
    signal GotFlushed : std_logic := '0';
    signal NotGotBubble : std_logic := '1';
    signal Reg1DataAfterHz : std_logic_vector(15 downto 0) := (others => '0');
    signal Reg2DataAfterHz : std_logic_vector(15 downto 0) := (others => '0');
    signal Reg1DataFromRF, Reg2DataFromRF : std_logic_vector(15 downto 0) := (others => '0');

    --Branch Predictor integration
    signal opcodeFromIF, opcodeFromID : std_logic_vector(3 downto 0);
    signal immFromID, PCFromIF, PCFromID, PCFromExToBP : std_logic_vector(15 downto 0) := (others => '0');
    signal branchPredictorPrediction : std_logic; -- 0: continuing with +2, 1: make changes, will get resolved @ALU
    signal PCOutFromBP : std_logic_vector(15 downto 0) := (others => '0'); --BP: branch predictor
    signal branchResultFromEx, performUpdateLogic, predictionForIF : std_logic;
    signal PCFromBranchHazard : std_logic_vector(15 downto 0);
    signal SignalFromBranchHazard : std_logic := '0'; --1: flush, 0: don't flush
    signal PCToBeFetched : std_logic_vector(15 downto 0) := (others => '0');
    signal TempSignalForTesting : std_logic;


begin
    branchPredictorALU1 : branchPredictorALU port map(
            opcode => opcodeFromID,
            PC => PCFromID,
            imm => immFromID,
            branchPredictor_prediction => branchPredictorPrediction,
            branchTarget => PCOutFromBP
        );

    -- connecting to ID stage and Ex stage
    branchPredictor1 : branchPredictor port map(
            clk => clk,
            opcode_atPCtoPredict => opcodeFromID,
            PCtoPredict => PCFromID,
            --From Ex
            PCtoUpdate => PCFromExToBP,
            branchResult => branchResultFromEx,
            performUpdate => performUpdateLogic,
            --To be used by branchPredictorALU to compute next branch
            predictBranchTaken => predictionForIF
        );
    IF_ID_Reg : NBitRegister
        generic map(N => 48, default => '0')
        port map(
            dataIn => FetchToDecodeDataIn,
            writeEnable => NotGotBubble,
            clk => clk,
            asyncReset => '0',
            dataOut => FetchToDecodeDataOut
        );

    ID_Reg_Reg: NBitRegister
        generic map(N => 50, default => '0')
        port map(
            dataIn => DecodeToRegFileDataIn,
            writeEnable => NotGotBubble,
            clk => clk,
            asyncReset => '0',
            dataOut => DecodeToRegFileDataOut
        );
    Reg_Ex_Reg: NBitRegister
        generic map(N => 82, default => '0')
        port map(
            dataIn => RegFileToExecDataIn,
            writeEnable => NotGotBubble,
            clk => clk,
            asyncReset => '0',
            dataOut => RegFileToExecDataOut
        );
    Ex_mem_Reg: NBitRegister
        generic map(N => 62, default => '0')
        port map(
            dataIn => ExecToMemDataIn,
            writeEnable => '1',
            clk => clk,
            asyncReset => '0',
            dataOut => ExecToMemDataOut
        );
    mem_Wb_Reg: NBitRegister
        generic map(N => 44, default => '0')
        port map(
            dataIn => MemToWBDataIn,
            writeEnable => '1',
            clk => clk,
            asyncReset => '0',
            dataOut => MemToWBDataOut
        );
    flagReg1 : flagReg port map(
        clk => clk, reset => resetFlags,
        SetZ => Z_Ex, Z => Z_FlagReg,
        SetC => C_Ex, C => C_FlagReg
    );
    instructionFetch1 : instructionFetch port map(
        clk => clk,
        PCtoFetch => PCToBeFetched,
        instruction => FetchToDecodeDataIn(15 downto 0),
        PCfromEx => PCFromBranchHazard,
        PCbranchSignal_Ex => SignalFromBranchHazard,
        PCOutFinal => FetchToDecodeDataIn(31 downto 16),
        GotBubbled => GotBubbled
    );
    instructionDecode1 : instructionDecoder port map(
        instruction => FetchToDecodeDataOut(15 downto 0),
        Ra => DecodeToRegFileDataIn(3 downto 1), Rb => DecodeToRegFileDataIn( 6 downto 4), Rc => DecodeToRegFileDataIn(9 downto 7),
        immediate => DecodeToRegFileDataIn(25 downto 10), condition => DecodeToRegFileDataIn(27 downto 26),
        useComplement => DecodeToRegFileDataIn(28),
        opcode => DecodeToRegFileDataIn(32 downto 29)
    );
    regFile1 : regFile port map(
        clk => clk,
        regWrite => regWriteEnable_WB,
        reg1Addr => DecodeToRegFileDataOut(3 downto 1), reg2Addr => DecodeToRegFileDataOut( 6 downto 4), reg3Addr => reg3Addr_WB,
        -- reg1Data => RegFileToExecDataIn(16 downto 1), reg2Data => RegFileToExecDataIn(32 downto 17), 
        reg1Data => Reg1DataFromRF, reg2Data => Reg2DataFromRF,
        reg3Data => reg3Data_WB,
        PC => PC_RF, PCtoRF => PCOutFinal_IF,
        reset => regResetSignal, updatePC => updatePCinRegFile, readPC => '1'
    );

    dataForwarder1 : dataForwarder port map(
        currentOpcode => DecodeToRegFileDataOut(32 downto 29),
        currentRegisterA => DecodeToRegFileDataOut(3 downto 1),
        -- currentRegisterAValue => RegFileToExecDataIn(16 downto 1),
        currentRegisterAValue => Reg1DataFromRF,
        currentRegisterB => DecodeToRegFileDataOut( 6 downto 4),
        -- currentRegisterBValue => RegFileToExecDataIn(32 downto 17),
        currentRegisterBValue => Reg2DataFromRF,

        execute_RegToWrite => ExecToMemDataIn(19 downto 17),
        execute_WriteEnable => ExecToMemDataIn(20),
        execute_RegValue => ExecToMemDataIn(16 downto 1),
        execute_opcode => RegFileToExecDataOut(64 downto 61),

        mem_RegToWrite => ExecToMemDataOut(19 downto 17),
        mem_WriteEnable => ExecToMemDataOut(20),
        mem_RegValue => ExecToMemDataOut(16 downto 1),
        mem_opcode => ExecToMemDataOut(60 downto 57),

        writeBack_RegToWrite => MemToWBDataOut(38 downto 36),
        writeBack_WriteEnable => MemToWBDataOut(18),
        writeBack_RegValue => MemToWBDataOut(35 downto 20),
        writeBack_opcode => MemToWBDataIn(43 downto 40),

        -- dataToUseAfterAccountingHazardsRegA => Reg1DataAfterHz,
        -- dataToUseAfterAccountingHazardsRegB => Reg2DataAfterHz,
        dataToUseAfterAccountingHazardsRegA => RegFileToExecDataIn(16 downto 1),
        dataToUseAfterAccountingHazardsRegB => RegFileToExecDataIn(32 downto 17),

        insertBubbleInPipeline => GotBubbled
    );
    execStage1 : execStage port map(
        opcode => RegFileToExecDataOut(64 downto 61),
        Ra => RegFileToExecDataOut(35 downto 33), Rb => RegFileToExecDataOut(38 downto 36), Rc => RegFileToExecDataOut(41 downto 39),
        RaValue => RegFileToExecDataOut(16 downto 1), RbValue => RegFileToExecDataOut(32 downto 17),
        -- RaValue => Reg1DataAfterHz, RbValue => Reg2DataAfterHz,
        immediate => RegFileToExecDataOut(57 downto 42), condition => RegFileToExecDataOut(59 downto 58),
        useComplement => RegFileToExecDataOut(60),
        PC => RegFileToExecDataOut(80 downto 65),
        PC_new => PCfrom_Ex,
        useNewPc => PCbranchSignal_Ex,
        regNewValue => ExecToMemDataIn(16 downto 1),
        regToWrite => ExecToMemDataIn(19 downto 17),
        writeReg => ExecToMemDataIn(20),
        zeroFlagIn => Z_FlagReg, zeroFlagOut => Z_Ex,
        carryFlagIn => C_FlagReg, carryFlagOut => C_Ex,
        RAM_Address => ExecToMemDataIn(36 downto 21),
        RAM_writeEnable => ExecToMemDataIn(37),
        RAM_DataToWrite => ExecToMemDataIn(53 downto 38),
        writeBackUseRAM_orALU => ExecToMemDataIn(54),
        writeBackEnable => ExecToMemDataIn(55),
        stallInstructionRead => ExecToMemDataIn(56),
        beenFlushed => RegFileToExecDataOut(0)
    );
    RAM1 : dataMemory port map(
        RAM_Address => ExecToMemDataOut(36 downto 21),
        RAM_Data_IN => ExecToMemDataOut(53 downto 38),
        RAM_Data_OUT => MemToWBDataIn(16 downto 1),
        RAM_Write => ExecToMemDataOut(37),
        RAM_Clock => clk
    );

    writeBack1 : writeBack port map(
        clk => clk,
        writeSignal => MemToWBDataOut(18),
        writeSignalOut => regWriteEnable_WB,
        selectSignalEx_RAM => MemToWBDataOut(17),
        writeDataIN_Ex => MemToWBDataOut(35 downto 20),
        writeDataIN_RAM => MemToWBDataOut(16 downto 1),
        writeDataOUT => reg3Data_WB,
        writeAddressIN => MemToWBDataOut(38 downto 36),
        writeAddressOUT => reg3Addr_WB,
        GotFlushed => MemToWBDataOut(0)
    );
    --Flushing the instructions in case of wrong branch
    DecodeToRegFileDataIn(0) <= GotFlushed;
    RegFileToExecDataIn(0) <= '1' when GotFlushed = '1' else DecodeToRegFileDataOut(0);
    FetchToDecodeDataIn(47 downto 32) <= PCToBeFetched;
    --Decode Stage linking
    -- DecodeToRegFileDataIn(48 downto 33) <= FetchToDecodeDataOut(31 downto 16); --PC
    DecodeToRegFileDataIn(48 downto 33) <= FetchToDecodeDataOut(47 downto 32);
    DecodeToRegFileDataIn(49) <= predictionForIF;
    --RgeFil Stage linking
    RegFileToExecDataIn(35 downto 33) <= DecodeToRegFileDataOut(3 downto 1); --Reg1Addr
    RegFileToExecDataIn(38 downto 36) <= DecodeToRegFileDataOut(6 downto 4); --Reg2Addr
    RegFileToExecDataIn(41 downto 39) <= DecodeToRegFileDataOut(9 downto 7); --Reg3Addr
    RegFileToExecDataIn(57 downto 42) <= DecodeToRegFileDataOut(25 downto 10); --Immediate
    RegFileToExecDataIn(59 downto 58) <= DecodeToRegFileDataOut(27 downto 26); --Condition
    RegFileToExecDataIn(60) <= DecodeToRegFileDataOut(28); --UseComplement
    RegFileToExecDataIn(64 downto 61) <= DecodeToRegFileDataOut(32 downto 29); --Opcode
    RegFileToExecDataIn(80 downto 65) <= DecodeToRegFileDataOut(48 downto 33); --PC
    RegFileToExecDataIn(81) <= DecodeToRegFileDataOut(49);
    --Exec Stage linking
    ExecToMemDataIn(0) <= RegFileToExecDataOut(0);
    ExecToMemDataIn(60 downto 57) <= RegFileToExecDataOut(64 downto 61); --Opcode
    ExecToMemDataIn(61) <= RegFileToExecDataOut(81);


    --Mem Stage linking
    MemToWBDataIn(0) <= ExecToMemDataOut(0); --Flush
    MemToWBDataIn(17) <= ExecToMemDataOut(54); --WriteBackUseRAM_orALU
    MemToWBDataIn(18) <= ExecToMemDataOut(55); --WriteBackEnable
    MemToWBDataIn(19) <= ExecToMemDataOut(56); --StallInstructionRead
    MemToWBDataIn(35 downto 20) <= ExecToMemDataOut(16 downto 1); --RegDataToWrite
    MemToWBDataIn(38 downto 36) <= ExecToMemDataOut(19 downto 17); --RegToWrite
    MemToWBDataIn(39) <= ExecToMemDataOut(20); --if writeReg
    MemToWBDataIn(43 downto 40) <= ExecToMemDataOut(60 downto 57);

    NotGotBubble <= not GotBubbled;

    PCOutFinal_IF <= FetchToDecodeDataIn(31 downto 16);

    --BP Linking
    opcodeFromID <= DecodeToRegFileDataIn(32 downto 29);
    PCFromID <= FetchToDecodeDataOut(47 downto 32);
    -- PCFromEx <= PCfrom_Ex;
    PCFromExToBP <= RegFileToExecDataOut(80 downto 65);
    branchResultFromEx <= PCbranchSignal_Ex;
    performUpdateLogic <= '0' when RegFileToExecDataOut(81) = PCbranchSignal_Ex else '1';
    branchPredictorPrediction <= predictionForIF;
    immFromID <= DecodeToRegFileDataIn(25 downto 10);
    SignalFromBranchHazard <= '0' when RegFileToExecDataOut(81) = PCbranchSignal_Ex else '1';
    -- TempSignalForTesting <= '0' when RegFileToExecDataOut(81) = PCbranchSignal_Ex else '1';
    -- SignalFromBranchHazard <= '0';
    GotFlushed <= SignalFromBranchHazard;
    -- PCFromBranchHazard <= std_logic_vector(unsigned(RegFileToExecDataOut(80 downto 65)) + 2) when
    --                             PCbranchSignal_Ex = '0' else PCfrom_Ex;
    PCFromBranchHazard <= std_logic_vector(unsigned(RegFileToExecDataOut(80 downto 65)) + 2) when
                                PCbranchSignal_Ex = '0' else PCfrom_Ex;
    PCToBeFetched <= PCOutFromBP when (SignalFromBranchHazard = '0' and branchPredictorPrediction = '1') else PC_RF when SignalFromBranchHazard = '0' or RegFileToExecDataOut(0) = '1' else PCFromBranchHazard;





    
    
    process
    variable OUTPUT_LINE: line;
    variable LINE_COUNT: integer := 0;
    variable i : integer := 0;
    File OUTFILE: text open write_mode is "testBench/IF_ID_RegTB.out";

    begin
        while i < 500 loop
            clk <= not clk;
            wait for 40 ns;
            i := i + 1;
            -- PCtoFetch <= PCOutFinal_IF;
            updatePCinRegFile <= not stallInstructionRead_Ex;
            clk <= not clk;
            wait for 40 ns;
        end loop;
    end process;
end whatever;