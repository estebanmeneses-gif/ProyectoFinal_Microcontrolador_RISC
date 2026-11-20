-- ============================================================================
-- MÓDULO: GeneradorEnable.vhd
-- DESCRIPCIÓN: Genera la habilitación de reloj (ce) del microcontrolador.
--              - lento = '0' : ce = '1' permanente (CPU a 50 MHz).
--              - lento = '1' : ce es un pulso de 1 ciclo cada DIVISOR ciclos
--                              (modo paso a paso visible en los displays).
--              No se crean relojes derivados: todo el diseño usa CLOCK_50.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY GeneradorEnable IS
    GENERIC (
        DIVISOR : INTEGER := 12_500_000  -- 50 MHz / 12.5 M = 4 instrucciones-ciclo/s
    );
    PORT (
        clk   : IN STD_LOGIC;  -- Reloj del sistema
        rst_n : IN STD_LOGIC;  -- Reset (activo bajo)
        lento : IN STD_LOGIC;  -- '1' = modo lento (SW8)
        ce    : OUT STD_LOGIC  -- Habilitación para la CPU
    );
END GeneradorEnable;

ARCHITECTURE behave OF GeneradorEnable IS
    SIGNAL cnt  : INTEGER RANGE 0 TO DIVISOR - 1 := 0;
    SIGNAL tick : STD_LOGIC := '0';
BEGIN
    PROCESS (clk, rst_n)
    BEGIN
        IF rst_n = '0' THEN
            cnt  <= 0;
            tick <= '0';
        ELSIF rising_edge(clk) THEN
            IF cnt = DIVISOR - 1 THEN
                cnt  <= 0;
                tick <= '1';
            ELSE
                cnt  <= cnt + 1;
                tick <= '0';
            END IF;
        END IF;
    END PROCESS;

    ce <= tick WHEN lento = '1' ELSE '1';
END behave;
