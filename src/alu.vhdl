LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ALU IS
    PORT (
        -- inputs for the ALU
        A, B : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        carryIn : IN STD_LOGIC;

        -- '0' for ADD and '1' for NAND
        op : STD_LOGIC;

        -- results of the operation
        result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        ZF, CF : OUT STD_LOGIC
    );
END ENTITY ALU;

ARCHITECTURE struct OF ALU IS
    SIGNAL m_A, m_B : STD_LOGIC_VECTOR(16 DOWNTO 0);
    SIGNAL m_nandResult : STD_LOGIC_VECTOR(16 DOWNTO 0);
    SIGNAL m_addResult : STD_LOGIC_VECTOR(16 DOWNTO 0);
    SIGNAL m_carryVector : STD_LOGIC_VECTOR(16 DOWNTO 0);
    SIGNAL m_finalResult : STD_LOGIC_VECTOR(16 DOWNTO 0);
BEGIN

    m_carryVector <= "0000000000000000" & carryIn;

    -- we want to generate carry flags from the addition
    -- if we use A and B directly, the result is not resized into 17 bits
    m_A <= '0' & A;
    m_B <= '0' & B;

    m_addResult <= STD_LOGIC_VECTOR(unsigned(m_A) + unsigned(m_B) + unsigned(m_carryVector));
    m_nandResult <= carryIn & (A NAND B);
    m_finalResult <= m_addResult WHEN op = '0' ELSE
        m_nandResult;

    ZF <= '1' WHEN (m_finalResult(15 DOWNTO 0) = "0000000000000000") ELSE
        '0';
    CF <= m_finalResult(16);

    result <= m_finalResult(15 DOWNTO 0);
END ARCHITECTURE struct;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ALU_wrapper IS
    PORT (
        -- inputs to be forwarded to the ALU
        -- the exact operation performed is dependent on the opcode
        -- see the doc for more details
        RaValue, RbValue, immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        condition : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        compliment : IN STD_LOGIC;
        ZF_prev, CF_prev : IN STD_LOGIC;

        -- results of the operation
        result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        ZF, CF : OUT STD_LOGIC;
        useResult : OUT STD_LOGIC
    );
END ENTITY ALU_wrapper;

ARCHITECTURE struct OF ALU_wrapper IS

    COMPONENT ALU IS
        PORT (
            A, B : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            carryIn : IN STD_LOGIC;
            op : IN STD_LOGIC;

            result : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            ZF, CF : OUT STD_LOGIC
        );
    END COMPONENT ALU;

    SIGNAL ALU_op : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL ALU_A, ALU_B : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL inpA, inpB : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL ALU_carryIn : STD_LOGIC;
    SIGNAL ZF_new, CF_new : STD_LOGIC;

    -- '0' is for ADD, '1' is for NAND
    SIGNAL m_toPerformAddOrNand : STD_LOGIC;
    SIGNAL m_useCarry : STD_LOGIC;
BEGIN

    ALU_A <= inpA;
    -- one has to be careful while testing as no opcode checks are done here
    -- may cause mistake with instructions like adi where compliment is not defined
    -- i.e is 0 always. this is handled by the instruction decoder.
    ALU_B <= inpB WHEN compliment = '0' ELSE
        NOT inpB;

    inpA <= RaValue WHEN (
        opcode = "0001" OR -- add rx, ry type instructions
        opcode = "0000" OR -- adi
        opcode = "0010" -- nand rx, ry type instructions
        ) ELSE
        RbValue WHEN(
        opcode = "0100" OR -- lw
        opcode = "0101" OR -- sw
        opcode = "0110" OR -- lm
        opcode = "0111" -- sm
        ) ELSE
        "0000000000000000"; -- lli

    inpB <= RbValue WHEN (
        opcode = "0001" OR -- add rx, ry type instructions
        opcode = "0010" -- nand rx, ry type instructions
        ) ELSE
        immediate WHEN (
        opcode = "0000" OR -- adi
        opcode = "0100" OR -- lw
        opcode = "0101" OR -- sw
        opcode = "0110" OR -- lm
        opcode = "0111" -- sm

        ) ELSE
        "0000000" & immediate(8 DOWNTO 0); -- lli
    ALU_carryIn <= CF_prev WHEN ((opcode = "0001" AND condition = "11") OR
        (opcode = "0010")) ELSE
        '0';

    WITH opcode SELECT -- adi, add, lw, sw, lli
        m_toPerformAddOrNand <= '0' WHEN "0000" | "0001" | "0100" | "0101" | "0011" | "0110" | "0111",
        '1' WHEN OTHERS;

    ALU_instance : ALU
    PORT MAP(
        A => ALU_A,
        B => ALU_B,
        carryIn => ALU_carryIn,
        op => m_toPerformAddOrNand,
        result => result,
        ZF => ZF_new,
        CF => CF_new
    );

    useResult <= '1' WHEN (opcode = "0001" AND (
        (condition = "00") OR -- ada and aca
        (condition = "01" AND ZF_prev = '1') OR -- adz and acz
        (condition = "10" AND CF_prev = '1') OR -- adc and acc
        (condition = "11") -- acw and awc
        )) OR
        (opcode = "0000") OR -- aci
        (opcode = "0010" AND (
        (condition = "00") OR -- ndu and ncu
        (condition = "10" AND CF_prev = '1') OR -- ndc and ncc
        (condition = "01" AND ZF_prev = '1') -- ndz and ncz
        )) ELSE
        '0';

    ZF <= ZF_new WHEN (opcode = "0001" AND (
        (condition = "00") OR -- ada and aca
        (condition = "01" AND ZF_prev = '1') OR -- adz and acz
        (condition = "10" AND CF_prev = '1') OR -- adc and acc
        (condition = "11") -- acw and awc
        )) OR
        (opcode = "0000") OR -- aci
        (opcode = "0010" AND (
        (condition = "00") OR -- ndu and ncu
        (condition = "10" AND CF_prev = '1') OR -- ndc and ncc
        (condition = "01" AND ZF_prev = '1') -- ndz and ncz
        )) ELSE
        ZF_prev;

    CF <= CF_new WHEN (opcode = "0001" AND (
        (condition = "00") OR -- ada and aca
        (condition = "01" AND ZF_prev = '1') OR -- adz and acz
        (condition = "10" AND CF_prev = '1') OR -- adc and acc
        (condition = "11") -- acw and awc
        )) OR
        (opcode = "0000") OR -- aci
        (opcode = "0010" AND (
        (condition = "00") OR -- ndu and ncu
        (condition = "10" AND CF_prev = '1') OR -- ndc and ncc
        (condition = "01" AND ZF_prev = '1') -- ndz and ncz
        )) ELSE
        CF_prev;

END ARCHITECTURE struct;