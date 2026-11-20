-- ============================================================================
-- MÓDULO: MemoriaDatos.vhd
-- DESCRIPCIÓN: Memoria RAM de datos de 16x8 bits con escritura síncrona
--              y lectura combinacional para las instrucciones LOAD y STORE.
--              Ocupa las direcciones 0x00 - 0x0F del mapa de memoria.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pkg_mcu.ALL;

ENTITY MemoriaDatos IS
    PORT (
        clk      : IN STD_LOGIC;                     -- Reloj del sistema
        ce       : IN STD_LOGIC;                     -- Habilitación de reloj
        ram_we   : IN STD_LOGIC;                     -- Escritura (STORE a la RAM)
        address  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);  -- Dirección de palabra
        data_in  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Dato a escribir
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Dato leído
    );
END MemoriaDatos;

ARCHITECTURE behave OF MemoriaDatos IS
    SIGNAL RAM_CONTENT : ram_array_t := (OTHERS => (OTHERS => '0'));
    SIGNAL addr_int    : INTEGER RANGE 0 TO RAM_DEPTH - 1;
BEGIN
    addr_int <= TO_INTEGER(UNSIGNED(address));

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF ce = '1' AND ram_we = '1' THEN
                RAM_CONTENT(addr_int) <= data_in;
            END IF;
        END IF;
    END PROCESS;

    data_out <= RAM_CONTENT(addr_int);
END behave;
