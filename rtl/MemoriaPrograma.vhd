-- ============================================================================
-- MÓDULO: MemoriaPrograma.vhd
-- DESCRIPCIÓN: Memoria ROM de programa de 64x8 bits (Arquitectura Harvard).
--              Lectura combinacional. Contiene el programa de control de
--              iluminación y ventilación (asm/programa.asm).
--              ARCHIVO GENERADO por asm/ensamblador.py - no editar a mano.
-- Etiquetas: INICIO=0x02, AUTO=0x0B, REV_TEMP=0x15, MANUAL=0x1F, ESCRIBIR=0x22
-- ============================================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.pkg_mcu.ALL;

ENTITY MemoriaPrograma IS
    PORT (
        address  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Dirección proveniente del PC
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  -- Instrucción / inmediato
    );
END MemoriaPrograma;

ARCHITECTURE behave OF MemoriaPrograma IS
    -- Formato: [ OpCode (4b) | Reg_A (2b) | Reg_B (2b) ]
    CONSTANT ROM_CONTENT : rom_array_t := (
         0 => "10101100", -- 0x00: AC  LDI   R3, 0xF0
         1 => "11110000", -- 0x01: F0      (inmediato)
         2 => "10110011", -- 0x02: B3  LOAD  R0, [R3]
         3 => "10101000", -- 0x03: A8  LDI   R2, 0x00
         4 => "00000000", -- 0x04: 00      (inmediato)
         5 => "11000010", -- 0x05: C2  STORE R0, [R2]
         6 => "10100100", -- 0x06: A4  LDI   R1, 0x80
         7 => "10000000", -- 0x07: 80      (inmediato)
         8 => "00110100", -- 0x08: 34  AND   R1, R0
         9 => "11100000", -- 0x09: E0  JZ    MANUAL
        10 => "00011111", -- 0x0A: 1F      (dirección)
        11 => "10100100", -- 0x0B: A4  LDI   R1, 0x80
        12 => "10000000", -- 0x0C: 80      (inmediato)
        13 => "10101000", -- 0x0D: A8  LDI   R2, 0x04
        14 => "00000100", -- 0x0E: 04      (inmediato)
        15 => "00111000", -- 0x0F: 38  AND   R2, R0
        16 => "11100000", -- 0x10: E0  JZ    REV_TEMP
        17 => "00010101", -- 0x11: 15      (dirección)
        18 => "10101000", -- 0x12: A8  LDI   R2, 0x01
        19 => "00000001", -- 0x13: 01      (inmediato)
        20 => "01000110", -- 0x14: 46  OR    R1, R2
        21 => "10101000", -- 0x15: A8  LDI   R2, 0x08
        22 => "00001000", -- 0x16: 08      (inmediato)
        23 => "00111000", -- 0x17: 38  AND   R2, R0
        24 => "11100000", -- 0x18: E0  JZ    ESCRIBIR
        25 => "00100010", -- 0x19: 22      (dirección)
        26 => "10101000", -- 0x1A: A8  LDI   R2, 0x02
        27 => "00000010", -- 0x1B: 02      (inmediato)
        28 => "01000110", -- 0x1C: 46  OR    R1, R2
        29 => "11010000", -- 0x1D: D0  JMP   ESCRIBIR
        30 => "00100010", -- 0x1E: 22      (dirección)
        31 => "10100100", -- 0x1F: A4  LDI   R1, 0x03
        32 => "00000011", -- 0x20: 03      (inmediato)
        33 => "00110100", -- 0x21: 34  AND   R1, R0
        34 => "01111100", -- 0x22: 7C  INC   R3
        35 => "11000111", -- 0x23: C7  STORE R1, [R3]
        36 => "10001100", -- 0x24: 8C  DEC   R3
        37 => "10101000", -- 0x25: A8  LDI   R2, 0x01
        38 => "00000001", -- 0x26: 01      (inmediato)
        39 => "11000110", -- 0x27: C6  STORE R1, [R2]
        40 => "01111000", -- 0x28: 78  INC   R2
        41 => "10110010", -- 0x29: B2  LOAD  R0, [R2]
        42 => "01110000", -- 0x2A: 70  INC   R0
        43 => "11000010", -- 0x2B: C2  STORE R0, [R2]
        44 => "11010000", -- 0x2C: D0  JMP   INICIO
        45 => "00000010", -- 0x2D: 02      (dirección)
        OTHERS => "00000000" -- NOP
    );
    SIGNAL addr_int : INTEGER RANGE 0 TO ROM_DEPTH - 1;
BEGIN
    -- Se usan los 6 bits menos significativos para direccionar 64 palabras
    addr_int <= TO_INTEGER(UNSIGNED(address(5 DOWNTO 0)));
    data_out <= ROM_CONTENT(addr_int);
END behave;
