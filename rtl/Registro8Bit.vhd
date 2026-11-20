-- ============================================================================
-- MÓDULO: Registro8Bit.vhd
-- DESCRIPCIÓN: Registro de 8 bits con habilitación de carga (load_en).
--              Se utiliza como Instruction Register (IR) para retener la
--              instrucción actual durante los ciclos de Decode y Execute.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Registro8Bit IS
    PORT (
        clk      : IN STD_LOGIC;                     -- Reloj del sistema
        rst_n    : IN STD_LOGIC;                     -- Reset asíncrono (activo bajo)
        ce       : IN STD_LOGIC;                     -- Habilitación de reloj
        load_en  : IN STD_LOGIC;                     -- '1' para capturar data_in
        data_in  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Entrada desde la ROM
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Instrucción actual estable
    );
END Registro8Bit;

ARCHITECTURE behave OF Registro8Bit IS
    SIGNAL reg_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            reg_data <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF ce = '1' AND load_en = '1' THEN
                reg_data <= data_in;
            END IF;
        END IF;
    END PROCESS;

    data_out <= reg_data;
END behave;
