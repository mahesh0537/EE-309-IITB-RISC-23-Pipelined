LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY execStage IS
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
END ENTITY execStage;

ARCHITECTURE impl OF execStage IS
    COMPONENT ALU_wrapper IS
        PORT (
            RaValue, RbValue, immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            condition : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            compliment : IN STD_LOGIC;
            ZF_prev, CF_prev : IN STD_LOGIC;

            result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            ZF, CF : OUT STD_LOGIC;
            useResult : OUT STD_LOGIC
        );
    END COMPONENT ALU_wrapper;

    COMPONENT conditionalBranchHandler IS
        PORT (
            opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            Ra, Rb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            imm : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            PC : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

            PC_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            useNewPc : OUT STD_LOGIC
        );
    END COMPONENT conditionalBranchHandler;

    COMPONENT unconditionalBranchHandler IS
        PORT (
            opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            PC : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Ra, Rb, immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

            RA_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            PC_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            useNewPc, useNewRa : OUT STD_LOGIC
        );
    END COMPONENT unconditionalBranchHandler;

    COMPONENT loadStoreHandler
        PORT (
            opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            Ra, Rb, Rc : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            RaValue, RbValue : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            ALU_result : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            ALU_resutWriteEnable : IN STD_LOGIC;

            RAM_Address : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            RAM_writeEnable : OUT STD_LOGIC;
            RAM_DataToWrite : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            writeBackUseRAM_orALU : OUT STD_LOGIC;
            writeBackEnable : OUT STD_LOGIC
        );
    END COMPONENT loadStoreHandler;

    SIGNAL ALU_ZF, ALU_CF : STD_LOGIC;
    SIGNAL ALU_result : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL ALU_useResult : STD_LOGIC;
    --signal ALU_A, ALU_B: std_logic_vector(15 downto 0);

    --signal m_ZeroFlag: std_logic := '0';
    --signal m_CarryFlag: std_logic := '0';

    -- CB is conditional Branch, UCB is unconditional branch
    SIGNAL CB_PC_new, UCB_PC_new : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL CB_useNewPC, UCB_useNewPC : STD_LOGIC;
    SIGNAL UCB_useNewRa : STD_LOGIC;
    SIGNAL UCB_RA_new : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL PC_plus2 : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

    ALU_wrapperInstance : ALU_wrapper
    PORT MAP(
        RaValue => RaValue,
        RbValue => RbValue,
        immediate => immediate,
        opcode => opcode,
        condition => condition,
        ZF_prev => ZeroFlagIn,
        CF_prev => CarryFlagIn,
        compliment => useComplement,

        result => ALU_result,
        ZF => ALU_ZF,
        CF => ALU_CF,
        useResult => ALU_useResult
    );

    UCBH_instance : unconditionalBranchHandler
    PORT MAP(
        opcode => opcode,
        PC => PC,
        Ra => RaValue,
        Rb => RbValue,
        immediate => immediate,

        Ra_new => UCB_RA_new,
        PC_new => UCB_PC_new,
        useNewPc => UCB_useNewPC,
        useNewRa => UCB_useNewRa
    );

    CBH_instance : conditionalBranchHandler
    PORT MAP(
        opcode => opcode,
        Ra => RaValue,
        Rb => RbValue,
        imm => immediate,
        PC => PC,

        PC_new => CB_PC_new,
        useNewPc => CB_useNewPC
    );

    LSH_instance : loadStoreHandler
    PORT MAP(
        opcode => opcode,
        Ra => Ra,
        Rb => Rb,
        Rc => Rc,
        RaValue => RaValue,
        RbValue => RbValue,
        immediate => immediate,
        ALU_result => ALU_result,
        ALU_resutWriteEnable => ALU_useResult,
        RAM_Address => RAM_Address,
        RAM_writeEnable => RAM_writeEnable,
        RAM_DataToWrite => RAM_DataToWrite,
        writeBackUseRAM_orALU => writeBackUseRAM_orALU,
        writeBackEnable => writeBackEnable
    );

    zeroFlagOut <= ALU_ZF WHEN ALU_useResult = '1' ELSE
        zeroFlagIn;
    carryFlagOut <= ALU_CF WHEN ALU_useResult = '1' ELSE
        carryFlagIn;

    -- whether we use the new result or not is decided by the writeReg flag
    regNewValue <= ALU_result WHEN ALU_useResult = '1' ELSE
        UCB_RA_new WHEN UCB_useNewRa = '1' ELSE
        ALU_result WHEN opcode = "0011" ELSE
        "0000000000000000";

    regToWrite <= Rc WHEN (ALU_useResult = '1' AND (opcode = "0001" OR opcode = "0010")) ELSE -- Rtype ADD and Rtype NAND instructions
        Ra WHEN (ALU_useResult = '1' AND opcode = "0000") ELSE
        Ra WHEN (UCB_useNewPC = '1') ELSE
        Ra WHEN opcode = "0011" OR opcode = "0110" OR opcode = "0100" ELSE
        "111"; -- lli instruction

    writeReg <= '1' WHEN ALU_useResult = '1' AND beenFlushed = '0' ELSE
        '0' WHEN CB_useNewPC = '1' ELSE
        UCB_useNewRa WHEN UCB_useNewPC = '1' AND beenFlushed = '0' ELSE
        '1' WHEN (opcode = "0011" OR opcode = "0100") AND beenFlushed = '0' ELSE
        '0';

    PC_new <= "0000000000000000" WHEN ALU_useResult = '1' ELSE
        CB_PC_new WHEN CB_useNewPC = '1' ELSE
        UCB_PC_new WHEN UCB_useNewPC = '1' ELSE
        "0000000000000000";

    useNewPc <= '0' WHEN ALU_useResult = '1' ELSE
        '1' WHEN CB_useNewPC = '1' ELSE
        '1' WHEN UCB_useNewPC = '1' ELSE
        '0';

    -- will use later when pipelining
    stallInstructionRead <= '0';
END ARCHITECTURE impl;