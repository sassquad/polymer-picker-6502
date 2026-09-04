; ============================================================================
; Polymer Picker - graphics module (plotshape + check)
; ----------------------------------------------------------------------------
; The EOR sprite plotter and the collision-in-box test, transcribed verbatim
; from the inline assembler in POLY2 (originally assembled to &900) and made
; relocatable BeebAsm labels. Semantics are byte-for-byte identical; only the
; addressing has been renamed to the memory-map symbols.
;
;   plotshape:  A = shape number (0..11), X = X coord, Y = Y coord.
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
;
; ----------------------------------------------------------------------------
; TWO IDEAS DO ALL THE WORK HERE - worth understanding before reading on.
;
; (1) EOR (exclusive-OR) plotting.  Instead of storing pixels, the plotter
;     XORs the sprite's bytes into whatever is already on screen:
;         screen = screen EOR sprite
;     XOR is its own inverse - do it twice and you are back where you started -
;     so the SAME call that draws a sprite also ERASES it. That is why the
;     whole engine moves a sprite by "draw at old position, draw at new": the
;     first draw rubs the old one out, the second paints the new one, and the
;     background survives untouched. No separate erase routine, no saved
;     background. The cost is that two overlapping sprites interfere (their
;     overlap cancels), which the game avoids by erasing before it redraws.
;
; (2) Self-modifying code.  The 6502 has no cheap way to call through a
;     pointer, so this routine PATCHES ITS OWN INSTRUCTIONS at run time: the
;     address in the sprite-fetch LDA, and the compare value in the row
;     counter, are written into the code bytes just before the loop runs. Look
;     for the labels tmpa, tmpb, shape and rowcounter sitting ON instruction
;     operands, and the STAs earlier that poke new values into "<label>+1".
;     The dummy operands below are &EE / &EEEE and get overwritten every call.
;
; ----------------------------------------------------------------------------
; MODE 2 SCREEN LAYOUT (needed to follow the address arithmetic).
;   160 x 256 pixels, 4 bits per pixel, so 2 pixels share one byte and a byte
;   is 20K / ... = 640 bytes make up one "character row" (8 pixel-lines tall).
;   The screen is a grid of 8x8-pixel character cells, stored cell by cell:
;     * within a cell the 8 vertical bytes of one 2-pixel-wide strip are at
;       CONSECUTIVE addresses (top line first),
;     * the next 2-pixel strip to the right is +8 bytes,
;     * the next character row DOWN is +640 bytes.
;   plotshape draws a sprite as a set of 2-pixel-wide COLUMNS (shapesize of
;   them), each shapedepth bytes tall, stepping +8 to the right between columns
;   and +640 when a column crosses a character-row boundary. Screen Y counts
;   UP the display, which is why the Y arithmetic below inverts it.
; ============================================================================

; ----------------------------------------------------------------------------
; plotshape - EOR-draw shape A at coordinate (X, Y).
;   First half: turn (X, Y) into the screen address of the sprite's top-left
;   2-pixel column, in zp_addr. Second half (.label): EOR the sprite's bytes
;   in, column by column.
; ----------------------------------------------------------------------------
.plotshape
    PHA                     ; save shape number - A/Y are needed for addressing

    ; --- scanline within the top character cell -------------------------------
    ; Screen Y runs up, cell scanlines run down, so (Y AND 7) EOR 7 gives the
    ; inverted line offset. It is stashed into the operand of the ORA at .tmpa,
    ; to be OR'd into the address low byte once the cell base is known.
    TYA
    AND #7
    EOR #7
    STA tmpa+1

    ; --- character row: Y DIV 8 selects the row_table entry -------------------
    ; row_table[r] holds the high byte of (&3000 + r*640). The low 3 bits went
    ; to the scanline above; here Y is shifted down to the row index. The extra
    ; ROR builds a half-carry (the +&100 within a 640-byte row) into .tmpb.
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
    TAY                     ; Y = high byte of the character-row base address

    ; --- X coordinate -> byte offset across the row --------------------------
    ; Each X step is one 2-pixel column = 8 bytes, so X is multiplied by 8.
    ; The two ASLs push the top bits out as carry; each carry means the offset
    ; has overflowed a page, so Y (the high byte) is bumped accordingly.
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
    ADC #&EE                ; + the row half-carry  (operand patched above)
.tmpa
    ORA #&EE                ; | the inverted scanline (operand patched above)
    STA zp_addr             ; zp_addr low byte is now final
    BCC skip3
    INY                     ; carry out of the low byte -> bump high byte
.skip3
    STY zp_addr+1           ; zp_addr now points at the sprite's top-left column

    ; --- look the shape up in the metadata tables ----------------------------
    ; shape+1/shape+2 form the operand of the sprite-fetch LDA at .shape, so
    ; writing the data pointer here aims that instruction at this shape's bytes.
    PLA
    TAY                     ; shape number back into Y
    LDA shapeloaddr,Y
    STA shape+1             ; low byte of sprite data address
    LDA shapehiaddr,Y
    STA shape+2             ; high byte
    LDA shapesize,Y
    STA zp_counter          ; columns still to draw
    LDA shapedepth,Y
    STA zp_depth            ; bytes per column

; --- outer loop: one pass per 2-pixel-wide column of the sprite --------------
.label
    LDY #0
    ; save this column's screen address on the stack; nextblock restores it and
    ; adds 8 to reach the column to the right.
    LDA zp_addr+1
    PHA
    LDA zp_addr
    PHA
    LDA zp_depth
    STA rowcounter+1        ; patch the row-count compare (= bytes per column)
    ; split the address into cell base (AND &F8) and scanline offset (AND 7):
    ; the inner loop uses (base),Y and walks Y down the 8 lines of the cell.
    LDA zp_addr
    TAX
    AND #7
    TAY
    TXA
    AND #&F8
    STA zp_addr
    LDX #0                  ; X counts bytes drawn down this column

; --- inner loop: EOR the sprite bytes down one column ------------------------
.innerloop
.shape
    LDA &EEEE,X             ; fetch next sprite byte  (address patched above)
    INX
    EOR (zp_addr),Y         ; the EOR draw/erase: screen = screen XOR sprite
    STA (zp_addr),Y
    INY
    CPY #8                  ; reached the bottom of this character cell?
    BEQ block               ;   yes - drop to the cell below (+640)
.noblock
.rowcounter
    CPX #&EE                ; done all bytes in this column?  (operand = depth)
    BNE innerloop

; --- advance to the next column to the right --------------------------------
.nextblock
    ; move the sprite-data pointer on by one column (depth bytes)
    LDA shape+1
    CLC
    ADC zp_depth
    STA shape+1
    BCC nohi
    INC shape+2
.nohi
    ; recover this column's screen address and add 8 -> next column right
    CLC
    PLA
    ADC #&08
    STA zp_addr
    PLA
    ADC #0
    STA zp_addr+1
    DEC zp_counter          ; one fewer column to go
    BNE label
    RTS                     ; whole sprite drawn

; --- cell boundary: the column crosses into the character row below ---------
.block
    LDY #0
    LDA zp_addr
    CLC
    ADC #&80
    STA zp_addr
    LDA zp_addr+1
    ADC #2                  ; +&280 total = +640 = one character row down
    BPL noboundary
    SEC
    SBC #&50                ; ran past &8000 -> wrap the screen back to &3000
.noboundary
    STA zp_addr+1
    BNE noblock             ; (always taken) resume the inner loop

; ----------------------------------------------------------------------------
; check - is point (X, Y) inside any of the 8 collision boxes?
;   Each box is 8x8, anchored at (arr_item_x[i], arr_item_y[i]). Scans i = 7
;   down to 0 and stops at the first hit. Writes the index to collide_result,
;   or &FF (negative) if nothing was hit - the caller tests that with BMI.
;   Y is used as both the loop index and, on a hit, the answer.
; ----------------------------------------------------------------------------
.check
    STX collide_x
    STY collide_y
    LDY #7
.checkloop
    LDA arr_item_x,Y
    CMP collide_x
    BCS notinbox            ; box left edge is right of the point -> miss
    CLC
    ADC #8
    CMP collide_x
    BCC notinbox            ; box right edge is left of the point -> miss
    LDA arr_item_y,Y
    CMP collide_y
    BCC notinbox            ; box top is below the point -> miss
    SEC
    SBC #8
    CMP collide_y
    BCC checkfinish         ; point is within the box's height -> HIT (Y = index)
.notinbox
    DEY
    BPL checkloop           ; try the next box; falls through when Y wraps to &FF
.checkfinish
    STY collide_result      ; box index on a hit, or &FF (negative) on a miss
    RTS

; ----------------------------------------------------------------------------
; Shape metadata (baked from the verified &2B00 sprite layout).
;   index: 0 LDIVER 1 RDIVER 2 LFISH 3 RFISH 4 LSHK
;          5 RSHK   6 DLFISH 7 DRFISH 8 FSHK  9 JELLY
;          10 crab  11 shrimp   (sea-bed critter, converted from UDGs at &0A30)
; Four parallel tables, indexed by the shape number:
;   shapeloaddr / shapehiaddr = address of the sprite's bytes
;   shapesize                 = number of 2-pixel columns (width)
;   shapedepth                = bytes per column (height in bytes)
; ----------------------------------------------------------------------------
.shapeloaddr
    EQUB <&2B00, <&2BC0, <&2C80, <&2CA0, <&2CC0, <&2DC0, <&2EC0, <&2EE0, <&2F00, <&2F80,<&0A30, <&0A50
.shapehiaddr
    EQUB >&2B00, >&2BC0, >&2C80, >&2CA0, >&2CC0, >&2DC0, >&2EC0, >&2EE0, >&2F00, >&2F80,>&0A30, >&0A50
.shapesize
    EQUB 12, 12, 4, 4, 16, 16, 4, 4, 8, 8,4, 4
.shapedepth
    EQUB 16, 16, 8, 8, 16, 16, 8, 8, 16, 16,8, 8
