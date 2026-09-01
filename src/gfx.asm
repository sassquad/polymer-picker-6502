; ============================================================================
; Polymer Picker - graphics module (plotshape + check)
; ----------------------------------------------------------------------------
; The EOR sprite plotter and the collision-in-box test, transcribed verbatim
; from the inline assembler in POLY2 (originally assembled to &900) and made
; relocatable BeebAsm labels. Semantics are byte-for-byte identical; only the
; addressing has been renamed to the memory-map symbols.
;
;   plotshape:  A = shape number (0..9), X = X coord, Y = Y coord.
;               Draws (EORs) the shape into the MODE 2 screen. Drawing the same
;               shape at the same place again erases it.
;   check:      X = X, Y = Y to test. Writes the hit box index (or a negative
;               value for "no hit") to collide_result (&AB2). Tests the 8 boxes
;               in arr_item_x/arr_item_y (&AE0/&AE8).
;
; The shape metadata tables are baked in here (see verified layout below),
; replacing POLY2's runtime DATA-fill.
;
; Requires INCLUDE "src/memorymap.asm" first (for zp_addr, row_table, etc.).
; row_table (&D01) must be populated before the first call.
; ============================================================================

.plotshape
    PHA                     ; save shape number
    ; --- derive screen address from X (coord) and Y (coord) ---
    TYA
    AND #7
    EOR #7
    STA tmpa+1
    TYA
    EOR #&F8
    LSR A
    LSR A
    LSR A
    TAY
    LSR A
    LDA #0
    ROR A
    STA tmpb+1
    LDA row_table,Y
    TAY
    TXA
    ASL A
    ASL A
    BCC skip1
    INY
    INY
.skip1
    ASL A
    BCC skip2
    INY
.skip2
    CLC
.tmpb
    ADC #&EE                ; operand patched above
.tmpa
    ORA #&EE                ; operand patched above
    STA zp_addr
    BCC skip3
    INY
.skip3
    STY zp_addr+1
    PLA
    TAY                     ; shape number back into Y
    LDA shapeloaddr,Y
    STA shape+1
    LDA shapehiaddr,Y
    STA shape+2
    LDA shapesize,Y
    STA zp_counter
    LDA shapedepth,Y
    STA zp_depth
.label
    LDY #0
    LDA zp_addr+1
    PHA
    LDA zp_addr
    PHA
    LDA zp_depth
    STA rowcounter+1
    LDA zp_addr
    TAX
    AND #7
    TAY
    TXA
    AND #&F8
    STA zp_addr
    LDX #0
.innerloop
.shape
    LDA &EEEE,X             ; address patched (shape+1/shape+2)
    INX
    EOR (zp_addr),Y
    STA (zp_addr),Y
    INY
    CPY #8
    BEQ block
.noblock
.rowcounter
    CPX #&EE                ; operand patched (= depth)
    BNE innerloop
.nextblock
    LDA shape+1
    CLC
    ADC zp_depth
    STA shape+1
    BCC nohi
    INC shape+2
.nohi
    CLC
    PLA
    ADC #&08
    STA zp_addr
    PLA
    ADC #0
    STA zp_addr+1
    DEC zp_counter
    BNE label
    RTS
.block
    LDY #0
    LDA zp_addr
    CLC
    ADC #&80
    STA zp_addr
    LDA zp_addr+1
    ADC #2
    BPL noboundary
    SEC
    SBC #&50                ; wrap &8000 -> &3000
.noboundary
    STA zp_addr+1
    BNE noblock

; ----------------------------------------------------------------------------
.check
    STX collide_x
    STY collide_y
    LDY #7
.checkloop
    LDA arr_item_x,Y
    CMP collide_x
    BCS notinbox            ; box X > test X
    CLC
    ADC #8
    CMP collide_x
    BCC notinbox            ; box X+8 < test X
    LDA arr_item_y,Y
    CMP collide_y
    BCC notinbox            ; box Y < test Y
    SEC
    SBC #8
    CMP collide_y
    BCC checkfinish         ; box Y-8 < test Y  (inverted check -> hit)
.notinbox
    DEY
    BPL checkloop
.checkfinish
    STY collide_result
    RTS

; ----------------------------------------------------------------------------
; Shape metadata (baked from the verified &2B00 sprite layout).
;   index: 0 LDIVER 1 RDIVER 2 LFISH 3 RFISH 4 LSHK
;          5 RSHK   6 DLFISH 7 DRFISH 8 FSHK  9 JELLY
; ----------------------------------------------------------------------------
.shapeloaddr
    EQUB <&2B00, <&2BC0, <&2C80, <&2CA0, <&2CC0, <&2DC0, <&2EC0, <&2EE0, <&2F00, <&2F80
.shapehiaddr
    EQUB >&2B00, >&2BC0, >&2C80, >&2CA0, >&2CC0, >&2DC0, >&2EC0, >&2EE0, >&2F00, >&2F80
.shapesize
    EQUB 12, 12, 4, 4, 16, 16, 4, 4, 8, 8
.shapedepth
    EQUB 16, 16, 8, 8, 16, 16, 8, 8, 16, 16
