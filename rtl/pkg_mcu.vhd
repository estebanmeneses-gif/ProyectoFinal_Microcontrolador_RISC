-- ============================================================================
-- MÓDULO: pkg_mcu.vhd
-- DESCRIPCIÓN: Paquete del microcontrolador RISC de 8 bits. Centraliza:
--              - Anchos de palabra y profundidad de las memorias.
--              - Códigos de operación (ISA) y selectores de la ALU.
--              - Mapa de memoria de datos (RAM + puertos de E/S).
--              - Tipos de memoria y función de conversión a 7 segmentos.
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE pkg_mcu IS
    -- ------------------------------------------------------------------------
    -- Dimensiones
    -- ------------------------------------------------------------------------
    CONSTANT DATA_WIDTH : INTEGER := 8;  -- Ancho de palabra (datos e instrucciones)
    CONSTANT ROM_DEPTH  : INTEGER := 64; -- Palabras de memoria de programa
    CONSTANT RAM_DEPTH  : INTEGER := 16; -- Palabras de memoria de datos

    SUBTYPE word_t IS STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    TYPE rom_array_t IS ARRAY (0 TO ROM_DEPTH - 1) OF word_t;
    TYPE ram_array_t IS ARRAY (0 TO RAM_DEPTH - 1) OF word_t;

    -- ------------------------------------------------------------------------
    -- Conjunto de instrucciones (formato [OpCode(4) | Ra(2) | Rb(2)])
    -- Las instrucciones LDI, JMP, JZ y JNZ ocupan 2 palabras:
    -- la segunda palabra es el dato inmediato o la dirección de salto.
    -- ------------------------------------------------------------------------
    CONSTANT OP_NOP   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000"; -- Sin operación
    CONSTANT OP_ADD   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001"; -- Ra = Ra + Rb
    CONSTANT OP_SUB   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010"; -- Ra = Ra - Rb
    CONSTANT OP_AND   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011"; -- Ra = Ra AND Rb
    CONSTANT OP_OR    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100"; -- Ra = Ra OR Rb
    CONSTANT OP_XOR   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101"; -- Ra = Ra XOR Rb
    CONSTANT OP_NOT   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110"; -- Ra = NOT Ra
    CONSTANT OP_INC   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111"; -- Ra = Ra + 1
    CONSTANT OP_DEC   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000"; -- Ra = Ra - 1
    CONSTANT OP_MOV   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001"; -- Ra = Rb
    CONSTANT OP_LDI   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010"; -- Ra = #imm8
    CONSTANT OP_LOAD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1011"; -- Ra = MEM[Rb]
    CONSTANT OP_STORE : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1100"; -- MEM[Rb] = Ra
    CONSTANT OP_JMP   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1101"; -- PC = dir
    CONSTANT OP_JZ    : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1110"; -- Si Z=1, PC = dir
    CONSTANT OP_JNZ   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1111"; -- Si Z=0, PC = dir

    -- ------------------------------------------------------------------------
    -- Selectores de la ALU
    -- ------------------------------------------------------------------------
    CONSTANT ALU_ADD  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    CONSTANT ALU_SUB  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT ALU_AND  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT ALU_OR   : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
    CONSTANT ALU_XOR  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    CONSTANT ALU_NOT  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    CONSTANT ALU_INC  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    CONSTANT ALU_DEC  : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
    CONSTANT ALU_PASB : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000"; -- Pasa B (MOV)

    -- ------------------------------------------------------------------------
    -- Fuente de escritura del banco de registros
    -- ------------------------------------------------------------------------
    CONSTANT SRC_ALU : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00"; -- Resultado ALU
    CONSTANT SRC_MEM : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01"; -- Bus de datos (RAM/E-S)
    CONSTANT SRC_IMM : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10"; -- Inmediato (ROM)

    -- ------------------------------------------------------------------------
    -- Mapa de memoria de datos
    --   0x00 - 0x0F : RAM de datos (16 bytes)
    --   0xF0        : Puerto de ENTRADA (solo lectura)
    --   0xF1        : Puerto de SALIDA  (lectura/escritura)
    -- ------------------------------------------------------------------------
    CONSTANT ADDR_IN_PORT  : word_t := x"F0";
    CONSTANT ADDR_OUT_PORT : word_t := x"F1";

    -- Bits del puerto de ENTRADA (0xF0)
    CONSTANT IN_SW_LUZ  : INTEGER := 0; -- Switch manual de iluminación
    CONSTANT IN_SW_VENT : INTEGER := 1; -- Switch manual de ventilación
    CONSTANT IN_OSCURO  : INTEGER := 2; -- Sensor de luz (1 = oscuro)
    CONSTANT IN_CALOR   : INTEGER := 3; -- Sensor de temperatura (1 = calor)
    CONSTANT IN_MODO    : INTEGER := 7; -- Modo (0 = manual, 1 = automático)

    -- Bits del puerto de SALIDA (0xF1)
    CONSTANT OUT_LUZ  : INTEGER := 0; -- Actuador de iluminación
    CONSTANT OUT_VENT : INTEGER := 1; -- Actuador de ventilación
    CONSTANT OUT_AUTO : INTEGER := 7; -- Indicador de modo automático

    -- ------------------------------------------------------------------------
    -- Displays de 7 segmentos (activos en bajo, orden gfedcba)
    -- ------------------------------------------------------------------------
    CONSTANT SEG_BLANK : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111111";
    FUNCTION hex_to_7seg(hex : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR;
END PACKAGE pkg_mcu;

PACKAGE BODY pkg_mcu IS
    FUNCTION hex_to_7seg(hex : STD_LOGIC_VECTOR(3 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        VARIABLE seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
    BEGIN
        CASE hex IS               -- gfedcba
            WHEN "0000" => seg := "1000000"; -- 0
            WHEN "0001" => seg := "1111001"; -- 1
            WHEN "0010" => seg := "0100100"; -- 2
            WHEN "0011" => seg := "0110000"; -- 3
            WHEN "0100" => seg := "0011001"; -- 4
            WHEN "0101" => seg := "0010010"; -- 5
            WHEN "0110" => seg := "0000010"; -- 6
            WHEN "0111" => seg := "1111000"; -- 7
            WHEN "1000" => seg := "0000000"; -- 8
            WHEN "1001" => seg := "0010000"; -- 9
            WHEN "1010" => seg := "0001000"; -- A
            WHEN "1011" => seg := "0000011"; -- b
            WHEN "1100" => seg := "1000110"; -- C
            WHEN "1101" => seg := "0100001"; -- d
            WHEN "1110" => seg := "0000110"; -- E
            WHEN "1111" => seg := "0001110"; -- F
            WHEN OTHERS => seg := SEG_BLANK;
        END CASE;
        RETURN seg;
    END FUNCTION hex_to_7seg;
END PACKAGE BODY pkg_mcu;
