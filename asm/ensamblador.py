#!/usr/bin/env python3
"""
ensamblador.py - Ensamblador de dos pasadas para el microcontrolador RISC de 8 bits.

Uso:
    python asm/ensamblador.py asm/programa.asm rtl/MemoriaPrograma.vhd

Formato de instrucción: [OpCode(4) | Ra(2) | Rb(2)]
LDI, JMP, JZ y JNZ ocupan dos palabras (la segunda es el inmediato o la dirección).
"""
import re
import sys

ROM_DEPTH = 64

OPCODES = {
    "NOP": 0x0, "ADD": 0x1, "SUB": 0x2, "AND": 0x3, "OR": 0x4, "XOR": 0x5,
    "NOT": 0x6, "INC": 0x7, "DEC": 0x8, "MOV": 0x9, "LDI": 0xA,
    "LOAD": 0xB, "STORE": 0xC, "JMP": 0xD, "JZ": 0xE, "JNZ": 0xF,
}
DOS_PALABRAS = {"LDI", "JMP", "JZ", "JNZ"}


def reg(tok):
    m = re.fullmatch(r"\[?R([0-3])\]?", tok.strip(), re.I)
    if not m:
        raise ValueError(f"registro inválido: {tok}")
    return int(m.group(1))


def num(tok, etiquetas):
    tok = tok.strip()
    if tok.upper() in etiquetas:
        return etiquetas[tok.upper()]
    return int(tok, 0) & 0xFF


def parsear(lineas):
    """Devuelve lista de (nro_linea, etiqueta, mnemonico, operandos, texto)."""
    salida = []
    for n, linea in enumerate(lineas, 1):
        texto = linea.split(";")[0].strip()
        if not texto:
            continue
        etiqueta = None
        m = re.match(r"^([A-Za-z_]\w*):\s*(.*)$", texto)
        if m:
            etiqueta, texto = m.group(1).upper(), m.group(2).strip()
        if texto:
            partes = texto.split(None, 1)
            mnem = partes[0].upper()
            ops = [o.strip() for o in partes[1].split(",")] if len(partes) > 1 else []
        else:
            mnem, ops = None, []
        salida.append((n, etiqueta, mnem, ops, linea.split(";")[0].strip()))
    return salida


def ensamblar(fuente):
    items = parsear(fuente.splitlines())
    # Pasada 1: direcciones de las etiquetas
    etiquetas, pc = {}, 0
    for _, et, mnem, _, _ in items:
        if et:
            etiquetas[et] = pc
        if mnem:
            pc += 2 if mnem in DOS_PALABRAS else 1
    # Pasada 2: código máquina
    rom, pc = [], 0
    for n, et, mnem, ops, txt in items:
        if not mnem:
            continue
        if mnem not in OPCODES:
            raise ValueError(f"línea {n}: mnemónico desconocido {mnem}")
        op = OPCODES[mnem] << 4
        if mnem in ("ADD", "SUB", "AND", "OR", "XOR", "MOV", "LOAD", "STORE"):
            w = op | reg(ops[0]) << 2 | reg(ops[1])
            rom.append((pc, w, txt)); pc += 1
        elif mnem in ("NOT", "INC", "DEC"):
            w = op | reg(ops[0]) << 2
            rom.append((pc, w, txt)); pc += 1
        elif mnem == "NOP":
            rom.append((pc, op, txt)); pc += 1
        elif mnem == "LDI":
            rom.append((pc, op | reg(ops[0]) << 2, txt))
            rom.append((pc + 1, num(ops[1], etiquetas), "    (inmediato)"))
            pc += 2
        else:  # JMP, JZ, JNZ
            rom.append((pc, op, txt))
            rom.append((pc + 1, num(ops[0], etiquetas), "    (dirección)"))
            pc += 2
    if pc > ROM_DEPTH:
        raise ValueError(f"el programa ocupa {pc} palabras (máx. {ROM_DEPTH})")
    return rom, etiquetas


def generar_vhdl(rom, etiquetas):
    lineas = []
    for dir_, w, txt in rom:
        lineas.append(f'        {dir_:2d} => "{w:08b}", -- 0x{dir_:02X}: {w:02X}  {txt}')
    tabla_et = ", ".join(f"{k}=0x{v:02X}" for k, v in etiquetas.items())
    cuerpo = "\n".join(lineas)
    return f"""-- ============================================================================
-- MÓDULO: MemoriaPrograma.vhd
-- DESCRIPCIÓN: Memoria ROM de programa de {ROM_DEPTH}x8 bits (Arquitectura Harvard).
--              Lectura combinacional. Contiene el programa de control de
--              iluminación y ventilación (asm/programa.asm).
--              ARCHIVO GENERADO por asm/ensamblador.py - no editar a mano.
-- Etiquetas: {tabla_et}
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
{cuerpo}
        OTHERS => "00000000" -- NOP
    );
    SIGNAL addr_int : INTEGER RANGE 0 TO ROM_DEPTH - 1;
BEGIN
    -- Se usan los 6 bits menos significativos para direccionar 64 palabras
    addr_int <= TO_INTEGER(UNSIGNED(address(5 DOWNTO 0)));
    data_out <= ROM_CONTENT(addr_int);
END behave;
"""


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    with open(sys.argv[1], encoding="utf-8") as f:
        rom, et = ensamblar(f.read())
    with open(sys.argv[2], "w", encoding="utf-8") as f:
        f.write(generar_vhdl(rom, et))
    print(f"{len(rom)} palabras generadas -> {sys.argv[2]}")
    for k, v in et.items():
        print(f"  {k:10s} = 0x{v:02X}")
