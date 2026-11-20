-- ============================================================================
-- MÓDULO: reset_sync.vhd
-- DESCRIPCIÓN: Sincronizador de reset. BUTTON0 de la DE0 es activo en bajo.
--              La activación del reset es asíncrona (efecto inmediato) y la
--              liberación es síncrona (2 flip-flops), lo que evita que los
--              registros salgan del reset en ciclos distintos.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reset_sync IS
    PORT (
        clk       : IN STD_LOGIC;  -- Reloj del sistema (50 MHz)
        rst_n_in  : IN STD_LOGIC;  -- Pulsador físico (activo bajo)
        rst_n_out : OUT STD_LOGIC  -- Reset interno sincronizado (activo bajo)
    );
END reset_sync;

ARCHITECTURE behave OF reset_sync IS
    SIGNAL ff1, ff2 : STD_LOGIC := '0';
BEGIN
    PROCESS (clk, rst_n_in)
    BEGIN
        IF rst_n_in = '0' THEN
            ff1 <= '0';
            ff2 <= '0';
        ELSIF rising_edge(clk) THEN
            ff1 <= '1';
            ff2 <= ff1;
        END IF;
    END PROCESS;

    rst_n_out <= ff2;
END behave;
