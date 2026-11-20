-- ============================================================================
-- MÓDULO: ALU.vhd
-- DESCRIPCIÓN: Unidad Aritmético-Lógica combinacional de 8 bits.
--              ADD, SUB, AND, OR, XOR, NOT, INC, DEC, PASS_B y bandera Zero.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pkg_mcu.ALL;

ENTITY ALU IS
    PORT (
        A       : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Operando A (Reg_A)
        B       : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Operando B (Reg_B)
        ALU_Sel : IN STD_LOGIC_VECTOR(3 DOWNTO 0);  -- Selector de operación
        Result  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Resultado de 8 bits
        Zero    : OUT STD_LOGIC                     -- '1' si Result = 0x00
    );
END ALU;

ARCHITECTURE behave OF ALU IS
    SIGNAL a_uns, b_uns, res_uns : UNSIGNED(7 DOWNTO 0);
BEGIN
    a_uns <= UNSIGNED(A);
    b_uns <= UNSIGNED(B);

    PROCESS (a_uns, b_uns, ALU_Sel)
    BEGIN
        CASE ALU_Sel IS
            WHEN ALU_ADD  => res_uns <= a_uns + b_uns;
            WHEN ALU_SUB  => res_uns <= a_uns - b_uns;
            WHEN ALU_AND  => res_uns <= a_uns AND b_uns;
            WHEN ALU_OR   => res_uns <= a_uns OR b_uns;
            WHEN ALU_XOR  => res_uns <= a_uns XOR b_uns;
            WHEN ALU_NOT  => res_uns <= NOT a_uns;
            WHEN ALU_INC  => res_uns <= a_uns + 1;
            WHEN ALU_DEC  => res_uns <= a_uns - 1;
            WHEN ALU_PASB => res_uns <= b_uns;
            WHEN OTHERS   => res_uns <= (OTHERS => '0');
        END CASE;
    END PROCESS;

    Result <= STD_LOGIC_VECTOR(res_uns);
    Zero   <= '1' WHEN res_uns = 0 ELSE '0';
END behave;
