LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY conditionalBranchHandler IS
    PORT (
        opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        Ra, Rb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        imm : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        PC : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        PC_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        useNewPc : OUT STD_LOGIC
    );
END ENTITY conditionalBranchHandler;

ARCHITECTURE impl OF conditionalBranchHandler IS
    SIGNAL m_branchTakenResult : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL m_branchNotTakenResult : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL m_Ra, m_Rb : unsigned(15 DOWNTO 0);
BEGIN
    m_Ra <= unsigned(Ra);
    m_Rb <= unsigned(Rb);
    m_branchTakenResult <= STD_LOGIC_VECTOR(unsigned(PC) + unsigned(imm) + unsigned(imm));
    m_branchNotTakenResult <= STD_LOGIC_VECTOR(unsigned(PC) + 2);
    PC_new <= m_branchTakenResult WHEN (
        ((opcode = "1000") AND (m_Ra = m_Rb)) OR
        ((opcode = "1001") AND (m_Ra < m_Rb)) OR
        ((opcode = "1010") AND (m_Ra <= m_Rb))
        ) ELSE
        m_branchNotTakenResult;

    -- useNewPc <= '1' when (
    -- 	(opcode = "1000") or
    -- 	(opcode = "1001") or
    -- 	(opcode = "1010")
    -- ) else '0';
    useNewPc <= '1' WHEN (
        ((opcode = "1000") AND (m_Ra = m_Rb)) OR
        ((opcode = "1001") AND (m_Ra < m_Rb)) OR
        ((opcode = "1010") AND (m_Ra <= m_Rb))
        ) ELSE
        '0';

END ARCHITECTURE impl;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY unconditionalBranchHandler IS
    PORT (
        opcode : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        PC : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        Ra, Rb, immediate : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        RA_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        PC_new : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        useNewPc, useNewRa : OUT STD_LOGIC
    );
END ENTITY unconditionalBranchHandler;

ARCHITECTURE impl OF unconditionalBranchHandler IS
BEGIN
    PC_new <= STD_LOGIC_VECTOR(unsigned(PC) + unsigned(immediate) + unsigned(immediate)) WHEN opcode = "1100" ELSE -- jal
        Rb WHEN opcode = "1101" ELSE -- jlr
        STD_LOGIC_VECTOR(unsigned(Ra) + unsigned(immediate) + unsigned(immediate)); -- jri

    -- use these results only if the opcode corresponds to a unconditional branch instruction
    useNewPc <= '1' WHEN (
        (opcode = "1100") OR -- jal
        (opcode = "1101") OR -- jlr
        (opcode = "1111") -- jri
        ) ELSE
        '0';

    RA_new <= STD_LOGIC_VECTOR(unsigned(PC) + 2);
    useNewRa <= '1' WHEN (opcode = "1100" OR opcode = "1101") ELSE
        '0';
END ARCHITECTURE impl;