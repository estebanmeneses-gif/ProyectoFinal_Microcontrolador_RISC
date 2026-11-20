-- ============================================================================
-- MÓDULO: BancoRegistros.vhd
-- DESCRIPCIÓN: Archivo de 4 registros de propósito general (R0 a R3) de 8 bits.
--              Escritura síncrona en el registro seleccionado por sel_a y
--              lectura combinacional de doble puerto (sel_a y sel_b).
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY BancoRegistros IS
    PORT (
        clk       : IN STD_LOGIC;                     -- Reloj del sistema
        rst_n     : IN STD_LOGIC;                     -- Reset asíncrono (activo bajo)
        ce        : IN STD_LOGIC;                     -- Habilitación de reloj
        reg_we    : IN STD_LOGIC;                     -- Habilitación de escritura
        sel_a     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);  -- Registro A (fuente/destino)
        sel_b     : IN STD_LOGIC_VECTOR(1 DOWNTO 0);  -- Registro B (fuente/puntero)
        data_in   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Dato a escribir en Reg_A
        reg_a_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Valor leído de Reg_A
        reg_b_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Valor leído de Reg_B
    );
END BancoRegistros;

ARCHITECTURE behave OF BancoRegistros IS
    TYPE reg_file_type IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL regs : reg_file_type;
BEGIN
    PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            regs <= (OTHERS => (OTHERS => '0'));     -- Todos los registros a 0
        ELSIF rising_edge(clk) THEN
            IF ce = '1' AND reg_we = '1' THEN
                regs(TO_INTEGER(UNSIGNED(sel_a))) <= data_in;
            END IF;
        END IF;
    END PROCESS;

    -- Lectura combinacional simultánea de ambos operandos
    reg_a_out <= regs(TO_INTEGER(UNSIGNED(sel_a)));
    reg_b_out <= regs(TO_INTEGER(UNSIGNED(sel_b)));
END behave;
