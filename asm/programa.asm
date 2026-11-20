; ============================================================================
; programa.asm - Control de iluminación y ventilación
; Microcontrolador RISC de 8 bits (Harvard) - Proyecto Final VHDL
;
; Mapa de memoria de datos:
;   0x00-0x0F RAM | 0xF0 puerto de ENTRADA | 0xF1 puerto de SALIDA
; Puerto de entrada : b0 SW luz, b1 SW vent, b2 oscuro, b3 calor, b7 modo
; Puerto de salida  : b0 luz, b1 ventilación, b7 indicador automático
; Uso de la RAM     : [0] copia de entradas, [1] última salida,
;                     [2] contador de iteraciones del lazo principal
; ============================================================================

        LDI   R3, 0xF0        ; R3 = puntero al puerto de entrada
INICIO:
        LOAD  R0, [R3]        ; R0 = entradas
        LDI   R2, 0x00
        STORE R0, [R2]        ; RAM[0] = copia de las entradas
        LDI   R1, 0x80
        AND   R1, R0          ; Z = 1 si SW9 = 0 (modo manual)
        JZ    MANUAL

AUTO:                         ; ---- Modo automático ----
        LDI   R1, 0x80        ; salida inicial: solo el indicador "auto"
        LDI   R2, 0x04
        AND   R2, R0          ; ¿está oscuro?
        JZ    REV_TEMP
        LDI   R2, 0x01
        OR    R1, R2          ; sí -> enciende la iluminación
REV_TEMP:
        LDI   R2, 0x08
        AND   R2, R0          ; ¿hace calor?
        JZ    ESCRIBIR
        LDI   R2, 0x02
        OR    R1, R2          ; sí -> enciende la ventilación
        JMP   ESCRIBIR

MANUAL:                       ; ---- Modo manual ----
        LDI   R1, 0x03
        AND   R1, R0          ; salida = SW1..SW0

ESCRIBIR:
        INC   R3              ; R3 = 0xF1 (puerto de salida)
        STORE R1, [R3]        ; actualiza los actuadores
        DEC   R3              ; R3 = 0xF0 de nuevo
        LDI   R2, 0x01
        STORE R1, [R2]        ; RAM[1] = última salida
        INC   R2              ; R2 = 0x02
        LOAD  R0, [R2]
        INC   R0
        STORE R0, [R2]        ; RAM[2] = RAM[2] + 1
        JMP   INICIO
