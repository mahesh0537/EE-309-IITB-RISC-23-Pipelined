LIBRARY std;
USE std.textio.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY CPU_main IS
    port (
        clk: in std_logic
    );
END ENTITY CPU_main;

ARCHITECTURE pipelineDataPath OF CPU_main IS
    COMPONENT instructionFetch IS
        PORT (
            clk : IN STD_LOGIC;
            PCtoFetch : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            instruction : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            PCfromEx : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            PCbranchSignal_Ex : IN STD_LOGIC;
            PCOutFinal : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            GotBubbled : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT dataForwarder IS
        PORT (
            -- the opcode of the instruction that is going to be executed
            currentOpcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

            -- the two inputs to the execute stage
            currentRegisterA : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            currentRegisterAValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            currentRegisterB : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            currentRegisterBValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

            execute_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            execute_WriteEnable : IN STD_LOGIC;
            execute_RegValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            execute_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            mem_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            mem_WriteEnable : IN STD_LOGIC;
            mem_RegValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            mem_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            writeBack_RegToWrite : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            writeBack_WriteEnable : IN STD_LOGIC;
            writeBack_RegValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            writeBack_opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);

            dataToUseAfterAccountingHazardsRegA : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            dataToUseAfterAccountingHazardsRegB : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

            insertBubbleInPipeline : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT instructionDecoder IS
        PORT (
            instruction : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Ra, Rb, Rc : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            immediate : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            condition : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            useComplement : OUT STD_LOGIC;
            opcode : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT regFile IS
        PORT (
            clk : IN STD_LOGIC;
            regWrite : IN STD_LOGIC;
            reg1Addr, reg2Addr, reg3Addr : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            reg1Data, reg2Data, PC : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            reg3Data, PCtoRF : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            reset : IN STD_LOGIC;
            updatePC : IN STD_LOGIC;
            readPC : IN STD_LOGIC --toggle to read PC, anytime
        );
    END COMPONENT;

    COMPONENT execStage IS
        PORT (
            opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            Ra, Rb, Rc : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            RaValue, RbValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            condition : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            useComplement : IN STD_LOGIC;
            PC : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

            -- this PC is to be used when a branch instruction is
            -- executed. otherwise, the default update is to be performed
            -- i.e. PC <- PC + 2
            PC_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            useNewPc : OUT STD_LOGIC;

            -- the new value of the register and wheter to write to it
            regNewValue : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            regToWrite : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            writeReg : OUT STD_LOGIC;

            zeroFlagIn : IN STD_LOGIC;
            zeroFlagOut : OUT STD_LOGIC;
            --		zeroFlagWriteEnable: in std_logic;

            carryFlagIn : IN STD_LOGIC;
            carryFlagOut : OUT STD_LOGIC;
            --		carryFlagWriteEnable: in std_logic;

            -- writing the result to RAM, instead of register file
            RAM_Address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            RAM_writeEnable : OUT STD_LOGIC;
            RAM_DataToWrite : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

            -- used for the load instruction
            -- tells us where we have to write the result of the
            -- load instruction, or that of the ALU/branch targets
            -- '1' is for RAM, '0' is for ALU
            writeBackUseRAM_orALU : OUT STD_LOGIC;
            writeBackEnable : OUT STD_LOGIC;

            stallInstructionRead : OUT STD_LOGIC;
            beenFlushed : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT dataMemory IS
        PORT (
            RAM_Address : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit address for read/write
            RAM_Data_IN : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit data for write
            RAM_Data_OUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16 bit data for read
            RAM_Write : IN STD_LOGIC; -- write enable
            RAM_Clock : IN STD_LOGIC -- clock
        );
    END COMPONENT;

    COMPONENT writeBack IS
        PORT (
            clk : IN STD_LOGIC;
            writeSignal : IN STD_LOGIC;
            writeSignalOut : OUT STD_LOGIC;
            selectSignalEx_RAM : IN STD_LOGIC;
            writeDataIN_Ex : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            writeDataIN_RAM : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            writeDataOUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            writeAddressIN : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            writeAddressOUT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            GotFlushed : IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT flagReg IS
        PORT (
            clk, reset : IN STD_LOGIC;
            SetZ : IN STD_LOGIC;
            Z : OUT STD_LOGIC;
            SetC : IN STD_LOGIC;
            C : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT NBitRegister IS
        GENERIC (
            N : INTEGER;
            DEFAULT : STD_LOGIC := '0'
        );
        PORT (
            dataIn : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
            writeEnable : IN STD_LOGIC;
            clk : IN STD_LOGIC;
            asyncReset : IN STD_LOGIC;
            dataOut : OUT STD_LOGIC_VECTOR(N - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT branchPredictor IS
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

            -- DB_index: in std_logic_vector(2 downto 0);
            -- DB_out: out std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    COMPONENT branchPredictorALU IS
        PORT (
            opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            PC, imm : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            branchPredictor_prediction : IN STD_LOGIC;

            branchTarget : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;
    --Signals
    -- SIGNAL clk : STD_LOGIC := '0';
    SIGNAL PCtoFetch : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL instruction_IF : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PCfrom_Ex : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL PCbranchSignal_Ex : STD_LOGIC := '0';
    SIGNAL PCOutFinal_IF : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL testvar : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    --Signal for Instruction Decoder
    SIGNAL Ra_ID, Rb_ID, Rc_ID : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL immediate_ID : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL condition_ID : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL useComplement_ID : STD_LOGIC := '0';
    SIGNAL opcode_ID : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');

    --Signal for Register File
    SIGNAL reg1Data_RF, reg2Data_RF, PC_RF : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL regResetSignal : STD_LOGIC := '0';
    SIGNAL updatePCinRegFile : STD_LOGIC := '0';
    --Signal for Exec
    SIGNAL reg3Data_Ex : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL reg3Addr_Ex : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RAM_Address_Ex : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RAM_writeEnable_Ex : STD_LOGIC := '0';
    SIGNAL RAM_DataToWrite_Ex : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL writeBackUseRAM_orALU_Ex : STD_LOGIC := '0';
    SIGNAL writeBackEnable_Ex : STD_LOGIC := '0';
    SIGNAL stallInstructionRead_Ex : STD_LOGIC := '0';

    --Signal for MEM
    SIGNAL RAM_Data_OUT_MEM : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    --Signal for WB
    SIGNAL regWriteEnable_WB : STD_LOGIC := '1';
    SIGNAL reg3Addr_WB : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '1');
    SIGNAL reg3Data_WB : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '1');

    --Signal for FlagReg
    SIGNAL Z_Ex, C_Ex : STD_LOGIC := '0';
    SIGNAL Z_FlagReg, C_FlagReg : STD_LOGIC := '0';
    SIGNAL resetFlags : STD_LOGIC := '0';
    -- signal randomSignal : std_logic := '0';
    --Signals for Pipeline Registers
    SIGNAL FetchToDecodeDataIn, FetchToDecodeDataOut : STD_LOGIC_VECTOR(47 DOWNTO 0) := (OTHERS => '0');
    SIGNAL DecodeToRegFileDataIn, DecodeToRegFileDataOut : STD_LOGIC_VECTOR(49 DOWNTO 0) := (OTHERS => '0');
    SIGNAL RegFileToExecDataIn, RegFileToExecDataOut : STD_LOGIC_VECTOR(81 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ExecToMemDataIn, ExecToMemDataOut : STD_LOGIC_VECTOR(61 DOWNTO 0) := (OTHERS => '0');
    SIGNAL MemToWBDataIn, MemToWBDataOut : STD_LOGIC_VECTOR(43 DOWNTO 0) := (OTHERS => '0');
    SIGNAL GotBubbled : STD_LOGIC := '0';
    SIGNAL GotFlushed : STD_LOGIC := '0';
    SIGNAL NotGotBubble : STD_LOGIC := '1';
    SIGNAL Reg1DataAfterHz : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Reg2DataAfterHz : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Reg1DataFromRF, Reg2DataFromRF : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    --Branch Predictor integration
    SIGNAL opcodeFromIF, opcodeFromID : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL immFromID, PCFromIF, PCFromID, PCFromExToBP : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL branchPredictorPrediction : STD_LOGIC; -- 0: continuing with +2, 1: make changes, will get resolved @ALU
    SIGNAL PCOutFromBP : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0'); --BP: branch predictor
    SIGNAL branchResultFromEx, performUpdateLogic, predictionForIF : STD_LOGIC;
    SIGNAL PCFromBranchHazard : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL SignalFromBranchHazard : STD_LOGIC := '0'; --1: flush, 0: don't flush
    SIGNAL PCToBeFetched : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL TempSignalForTesting : STD_LOGIC;
BEGIN
    branchPredictorALU1 : branchPredictorALU PORT MAP(
        opcode => opcodeFromID,
        PC => PCFromID,
        imm => immFromID,
        branchPredictor_prediction => branchPredictorPrediction,
        branchTarget => PCOutFromBP
    );

    -- connecting to ID stage and Ex stage
    BranchPredictorInstance : branchPredictor PORT MAP(
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
    PipelineReg_IF_ID : NBitRegister
    GENERIC MAP(N => 48, DEFAULT => '0')
    PORT MAP(
        dataIn => FetchToDecodeDataIn,
        writeEnable => NotGotBubble,
        clk => clk,
        asyncReset => '0',
        dataOut => FetchToDecodeDataOut
    );

    PipelineReg_ID_RF : NBitRegister
    GENERIC MAP(N => 50, DEFAULT => '0')
    PORT MAP(
        dataIn => DecodeToRegFileDataIn,
        writeEnable => NotGotBubble,
        clk => clk,
        asyncReset => '0',
        dataOut => DecodeToRegFileDataOut
    );

    PipelineReg_RF_Ex : NBitRegister
    GENERIC MAP(N => 82, DEFAULT => '0')
    PORT MAP(
        dataIn => RegFileToExecDataIn,
        writeEnable => '1',
        clk => clk,
        asyncReset => '0',
        dataOut => RegFileToExecDataOut
    );
    
    PipelineReg_Ex_mem : NBitRegister
    GENERIC MAP(N => 62, DEFAULT => '0')
    PORT MAP(
        dataIn => ExecToMemDataIn,
        writeEnable => '1',
        clk => clk,
        asyncReset => '0',
        dataOut => ExecToMemDataOut
    );

    PipelineReg_Mem_WB : NBitRegister
    GENERIC MAP(N => 44, DEFAULT => '0')
    PORT MAP(
        dataIn => MemToWBDataIn,
        writeEnable => '1',
        clk => clk,
        asyncReset => '0',
        dataOut => MemToWBDataOut
    );

    flagRegInstance : flagReg PORT MAP(
        clk => clk, reset => resetFlags,
        SetZ => Z_Ex, Z => Z_FlagReg,
        SetC => C_Ex, C => C_FlagReg
    );

    instructionFetchInstance : instructionFetch PORT MAP(
        clk => clk,
        PCtoFetch => PCToBeFetched,
        instruction => FetchToDecodeDataIn(15 DOWNTO 0),
        PCfromEx => PCFromBranchHazard,
        PCbranchSignal_Ex => SignalFromBranchHazard,
        PCOutFinal => FetchToDecodeDataIn(31 DOWNTO 16),
        GotBubbled => GotBubbled
    );

    instructionDecoderInstance : instructionDecoder PORT MAP(
        instruction => FetchToDecodeDataOut(15 DOWNTO 0),
        Ra => DecodeToRegFileDataIn(3 DOWNTO 1), Rb => DecodeToRegFileDataIn(6 DOWNTO 4), Rc => DecodeToRegFileDataIn(9 DOWNTO 7),
        immediate => DecodeToRegFileDataIn(25 DOWNTO 10), condition => DecodeToRegFileDataIn(27 DOWNTO 26),
        useComplement => DecodeToRegFileDataIn(28),
        opcode => DecodeToRegFileDataIn(32 DOWNTO 29)
    );

    regFileInstance : regFile PORT MAP(
        clk => clk,
        regWrite => regWriteEnable_WB,
        reg1Addr => DecodeToRegFileDataOut(3 DOWNTO 1), reg2Addr => DecodeToRegFileDataOut(6 DOWNTO 4), reg3Addr => reg3Addr_WB,
        -- reg1Data => RegFileToExecDataIn(16 downto 1), reg2Data => RegFileToExecDataIn(32 downto 17), 
        reg1Data => Reg1DataFromRF, reg2Data => Reg2DataFromRF,
        reg3Data => reg3Data_WB,
        PC => PC_RF, PCtoRF => PCOutFinal_IF,
        reset => regResetSignal, updatePC => updatePCinRegFile, readPC => '1'
    );

    dataForwarderInstance : dataForwarder PORT MAP(
        currentOpcode => DecodeToRegFileDataOut(32 DOWNTO 29),
        currentRegisterA => DecodeToRegFileDataOut(3 DOWNTO 1),
        -- currentRegisterAValue => RegFileToExecDataIn(16 downto 1),
        currentRegisterAValue => Reg1DataFromRF,
        currentRegisterB => DecodeToRegFileDataOut(6 DOWNTO 4),
        -- currentRegisterBValue => RegFileToExecDataIn(32 downto 17),
        currentRegisterBValue => Reg2DataFromRF,

        execute_RegToWrite => ExecToMemDataIn(19 DOWNTO 17),
        execute_WriteEnable => ExecToMemDataIn(20),
        execute_RegValue => ExecToMemDataIn(16 DOWNTO 1),
        execute_opcode => RegFileToExecDataOut(64 DOWNTO 61),

        mem_RegToWrite => ExecToMemDataOut(19 DOWNTO 17),
        mem_WriteEnable => ExecToMemDataOut(20),
        mem_RegValue => ExecToMemDataOut(16 DOWNTO 1),
        mem_opcode => ExecToMemDataOut(60 DOWNTO 57),

        writeBack_RegToWrite => MemToWBDataOut(38 DOWNTO 36),
        writeBack_WriteEnable => MemToWBDataOut(18),
        writeBack_RegValue => MemToWBDataOut(35 DOWNTO 20),
        writeBack_opcode => MemToWBDataIn(43 DOWNTO 40),

        -- dataToUseAfterAccountingHazardsRegA => Reg1DataAfterHz,
        -- dataToUseAfterAccountingHazardsRegB => Reg2DataAfterHz,
        dataToUseAfterAccountingHazardsRegA => RegFileToExecDataIn(16 DOWNTO 1),
        dataToUseAfterAccountingHazardsRegB => RegFileToExecDataIn(32 DOWNTO 17),

        insertBubbleInPipeline => GotBubbled
    );

    execStageInstance : execStage PORT MAP(
        opcode => RegFileToExecDataOut(64 DOWNTO 61),
        Ra => RegFileToExecDataOut(35 DOWNTO 33), Rb => RegFileToExecDataOut(38 DOWNTO 36), Rc => RegFileToExecDataOut(41 DOWNTO 39),
        RaValue => RegFileToExecDataOut(16 DOWNTO 1), RbValue => RegFileToExecDataOut(32 DOWNTO 17),
        -- RaValue => Reg1DataAfterHz, RbValue => Reg2DataAfterHz,
        immediate => RegFileToExecDataOut(57 DOWNTO 42), condition => RegFileToExecDataOut(59 DOWNTO 58),
        useComplement => RegFileToExecDataOut(60),
        PC => RegFileToExecDataOut(80 DOWNTO 65),
        PC_new => PCfrom_Ex,
        useNewPc => PCbranchSignal_Ex,
        regNewValue => ExecToMemDataIn(16 DOWNTO 1),
        regToWrite => ExecToMemDataIn(19 DOWNTO 17),
        writeReg => ExecToMemDataIn(20),
        zeroFlagIn => Z_FlagReg, zeroFlagOut => Z_Ex,
        carryFlagIn => C_FlagReg, carryFlagOut => C_Ex,
        RAM_Address => ExecToMemDataIn(36 DOWNTO 21),
        RAM_writeEnable => ExecToMemDataIn(37),
        RAM_DataToWrite => ExecToMemDataIn(53 DOWNTO 38),
        writeBackUseRAM_orALU => ExecToMemDataIn(54),
        writeBackEnable => ExecToMemDataIn(55),
        stallInstructionRead => ExecToMemDataIn(56),
        beenFlushed => RegFileToExecDataOut(0)
    );

    RAM_instance : dataMemory PORT MAP(
        RAM_Address => ExecToMemDataOut(36 DOWNTO 21),
        RAM_Data_IN => ExecToMemDataOut(53 DOWNTO 38),
        RAM_Data_OUT => MemToWBDataIn(16 DOWNTO 1),
        RAM_Write => ExecToMemDataOut(37),
        RAM_Clock => clk
    );

    writeBackInstance : writeBack PORT MAP(
        clk => clk,
        writeSignal => MemToWBDataOut(18),
        writeSignalOut => regWriteEnable_WB,
        selectSignalEx_RAM => MemToWBDataOut(17),
        writeDataIN_Ex => MemToWBDataOut(35 DOWNTO 20),
        writeDataIN_RAM => MemToWBDataOut(16 DOWNTO 1),
        writeDataOUT => reg3Data_WB,
        writeAddressIN => MemToWBDataOut(38 DOWNTO 36),
        writeAddressOUT => reg3Addr_WB,
        GotFlushed => MemToWBDataOut(0)
    );

    --Flushing the instructions in case of wrong branch
    DecodeToRegFileDataIn(0) <= GotFlushed;
    RegFileToExecDataIn(0) <= '1' WHEN GotFlushed = '1' ELSE
    DecodeToRegFileDataOut(0);
    FetchToDecodeDataIn(47 DOWNTO 32) <= PCToBeFetched;

    --Decode Stage linking
    -- DecodeToRegFileDataIn(48 downto 33) <= FetchToDecodeDataOut(31 downto 16); --PC
    DecodeToRegFileDataIn(48 DOWNTO 33) <= FetchToDecodeDataOut(47 DOWNTO 32);
    DecodeToRegFileDataIn(49) <= predictionForIF;

    --RgeFil Stage linking
    RegFileToExecDataIn(35 DOWNTO 33) <= DecodeToRegFileDataOut(3 DOWNTO 1); --Reg1Addr
    RegFileToExecDataIn(38 DOWNTO 36) <= DecodeToRegFileDataOut(6 DOWNTO 4); --Reg2Addr
    RegFileToExecDataIn(41 DOWNTO 39) <= DecodeToRegFileDataOut(9 DOWNTO 7); --Reg3Addr
    RegFileToExecDataIn(57 DOWNTO 42) <= DecodeToRegFileDataOut(25 DOWNTO 10); --Immediate
    RegFileToExecDataIn(59 DOWNTO 58) <= DecodeToRegFileDataOut(27 DOWNTO 26); --Condition
    RegFileToExecDataIn(60) <= DecodeToRegFileDataOut(28); --UseComplement
    RegFileToExecDataIn(64 DOWNTO 61) <= DecodeToRegFileDataOut(32 DOWNTO 29); --Opcode
    RegFileToExecDataIn(80 DOWNTO 65) <= DecodeToRegFileDataOut(48 DOWNTO 33); --PC
    RegFileToExecDataIn(81) <= DecodeToRegFileDataOut(49);

    --Exec Stage linking
    ExecToMemDataIn(0) <= RegFileToExecDataOut(0);
    ExecToMemDataIn(60 DOWNTO 57) <= RegFileToExecDataOut(64 DOWNTO 61); --Opcode
    ExecToMemDataIn(61) <= RegFileToExecDataOut(81);

    --Mem Stage linking
    MemToWBDataIn(0) <= ExecToMemDataOut(0); --Flush
    MemToWBDataIn(17) <= ExecToMemDataOut(54); --WriteBackUseRAM_orALU
    MemToWBDataIn(18) <= ExecToMemDataOut(55); --WriteBackEnable
    MemToWBDataIn(19) <= ExecToMemDataOut(56); --StallInstructionRead
    MemToWBDataIn(35 DOWNTO 20) <= ExecToMemDataOut(16 DOWNTO 1); --RegDataToWrite
    MemToWBDataIn(38 DOWNTO 36) <= ExecToMemDataOut(19 DOWNTO 17); --RegToWrite
    MemToWBDataIn(39) <= ExecToMemDataOut(20); --if writeReg
    MemToWBDataIn(43 DOWNTO 40) <= ExecToMemDataOut(60 DOWNTO 57);

    NotGotBubble <= NOT GotBubbled;

    PCOutFinal_IF <= FetchToDecodeDataIn(31 DOWNTO 16);

    --BP Linking
    opcodeFromID <= DecodeToRegFileDataIn(32 DOWNTO 29);
    PCFromID <= FetchToDecodeDataOut(47 DOWNTO 32);
    PCFromExToBP <= RegFileToExecDataOut(80 DOWNTO 65);
    branchResultFromEx <= PCbranchSignal_Ex;
    performUpdateLogic <= '0' WHEN RegFileToExecDataOut(81) = PCbranchSignal_Ex ELSE
        '1';
    branchPredictorPrediction <= predictionForIF;
    immFromID <= DecodeToRegFileDataIn(25 DOWNTO 10);
    SignalFromBranchHazard <= '0' WHEN RegFileToExecDataOut(81) = PCbranchSignal_Ex ELSE
        '1';
    GotFlushed <= SignalFromBranchHazard;
    PCFromBranchHazard <= STD_LOGIC_VECTOR(unsigned(RegFileToExecDataOut(80 DOWNTO 65)) + 2) WHEN
        PCbranchSignal_Ex = '0' ELSE
        PCfrom_Ex;
    PCToBeFetched <= PCOutFromBP WHEN (SignalFromBranchHazard = '0' AND branchPredictorPrediction = '1') ELSE
        PC_RF WHEN SignalFromBranchHazard = '0' OR RegFileToExecDataOut(0) = '1' ELSE
        PCFromBranchHazard;

    PROCESS (clk, stallInstructionRead_Ex)
    BEGIN
        IF rising_edge(clk) THEN
                updatePCinRegFile <= NOT stallInstructionRead_Ex;
        END IF;
    END PROCESS;

--    dummy <= clk;


END ARCHITECTURE pipelineDataPath;