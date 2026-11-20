-- ============================================================================
-- MÓDULO: ProgramCounter.vhd
-- DESCRIPCIÓN: Contador de programa de 8 bits con incremento sincrónico,
--              carga paralela (saltos JMP/JZ/JNZ), habilitación de reloj (ce)
--              y reset asíncrono.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ProgramCounter IS
    PORT (
        clk     : IN STD_LOGIC;                     -- Reloj del sistema
        rst_n   : IN STD_LOGIC;                     -- Reset asíncrono (activo bajo)
        ce      : IN STD_LOGIC;                     -- Habilitación de reloj
        pc_inc  : IN STD_LOGIC;                     -- '1' para incrementar (PC + 1)
        pc_load : IN STD_LOGIC;                     -- '1' para cargar dirección de salto
        data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Dirección destino (desde ROM)
        pc_out  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Dirección actual hacia la ROM
    );
END ProgramCounter;

ARCHITECTURE behave OF ProgramCounter IS
    SIGNAL pc_reg : UNSIGNED(7 DOWNTO 0);
BEGIN
    PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            pc_reg <= (OTHERS => '0');               -- Inicia en dirección 0x00
        ELSIF rising_edge(clk) THEN
            IF ce = '1' THEN
                IF pc_load = '1' THEN
                    pc_reg <= UNSIGNED(data_in);     -- Salto
                ELSIF pc_inc = '1' THEN
                    pc_reg <= pc_reg + 1;            -- Avance normal
                END IF;
            END IF;
        END IF;
    END PROCESS;

    pc_out <= STD_LOGIC_VECTOR(pc_reg);
END behave;
