-- ============================================================================
-- TESTBENCH: tb_ALU.vhd
-- DESCRIPCIÓN: Verificación autocomprobable de las 9 operaciones de la ALU y
--              de la bandera Zero, con vectores que incluyen desbordamientos.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pkg_mcu.ALL;

ENTITY tb_ALU IS
END tb_ALU;

ARCHITECTURE sim OF tb_ALU IS
    SIGNAL A, B, R : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL S       : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL Z       : STD_LOGIC;
BEGIN
    DUT : ENTITY work.ALU
        PORT MAP (A => A, B => B, ALU_Sel => S, Result => R, Zero => Z);

    PROCESS
        VARIABLE errores : INTEGER := 0;
        PROCEDURE probar(op : STD_LOGIC_VECTOR(3 DOWNTO 0); va, vb, esperado : INTEGER;
                         nombre : STRING) IS
            VARIABLE zesp : STD_LOGIC;
        BEGIN
            A <= STD_LOGIC_VECTOR(TO_UNSIGNED(va, 8));
            B <= STD_LOGIC_VECTOR(TO_UNSIGNED(vb, 8));
            S <= op;
            WAIT FOR 10 ns;
            IF esperado = 0 THEN zesp := '1'; ELSE zesp := '0'; END IF;
            IF TO_INTEGER(UNSIGNED(R)) /= esperado OR Z /= zesp THEN
                REPORT "FALLA " & nombre & ": obtenido " & INTEGER'IMAGE(TO_INTEGER(UNSIGNED(R)))
                    & " esperado " & INTEGER'IMAGE(esperado) SEVERITY ERROR;
                errores := errores + 1;
            END IF;
        END PROCEDURE;
    BEGIN
        probar(ALU_ADD,    5,   3,   8, "ADD 5+3");
        probar(ALU_ADD,  255,   1,   0, "ADD 255+1 (desborde, Z=1)");
        probar(ALU_SUB,    9,   3,   6, "SUB 9-3");
        probar(ALU_SUB,    3,   3,   0, "SUB 3-3 (Z=1)");
        probar(ALU_SUB,    0,   1, 255, "SUB 0-1 (préstamo)");
        probar(ALU_AND, 16#8F#, 16#80#, 16#80#, "AND máscara modo");
        probar(ALU_AND, 16#0F#, 16#80#, 0, "AND sin modo (Z=1)");
        probar(ALU_OR,  16#80#, 16#01#, 16#81#, "OR");
        probar(ALU_XOR, 16#FF#, 16#0F#, 16#F0#, "XOR");
        probar(ALU_XOR, 16#AA#, 16#AA#, 0, "XOR igual (Z=1)");
        probar(ALU_NOT, 16#0F#, 0, 16#F0#, "NOT");
        probar(ALU_INC, 16#F0#, 0, 16#F1#, "INC F0");
        probar(ALU_INC, 255, 0, 0, "INC 255 (Z=1)");
        probar(ALU_DEC, 16#F1#, 0, 16#F0#, "DEC F1");
        probar(ALU_DEC, 1, 0, 0, "DEC 1 (Z=1)");
        probar(ALU_PASB, 7, 42, 42, "PASS_B (MOV)");
        probar("1111", 7, 42, 0, "Selector no usado -> 0");

        IF errores = 0 THEN
            REPORT "tb_ALU: 17/17 vectores PASAN" SEVERITY NOTE;
        ELSE
            REPORT "tb_ALU: " & INTEGER'IMAGE(errores) & " errores" SEVERITY FAILURE;
        END IF;
        WAIT;
    END PROCESS;
END sim;
