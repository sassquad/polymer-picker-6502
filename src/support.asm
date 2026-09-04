; ============================================================================
; Polymer Picker - support code and data loaded alongside the engine
; ----------------------------------------------------------------------------
; Two small pieces the engine needs but which are not part of it:
;   * COPY - the page copier that relocates the engine down to &0E00
;   * UDG  - the user-defined character shapes for the scenery and HUD
; Both are plain PUTFILE/*LOAD blobs; neither is called from the game loop.
; ============================================================================

; ----------------------------------------------------------------------------
; Page copier.  The engine cannot be loaded straight to its run address &0E00,
; because that is the disc system's own workspace (see the DFS rules in
; memorymap.asm). So BASIC loads the engine into spare screen RAM at &5000,
; switches the disc off with *TAPE - which frees &0E00 - then calls this to
; block-copy the image down.
;
; It copies 15 whole pages (3840 bytes). The trick worth noticing: the source
; and destination addresses in the two instructions .csrc and .cdst are PATCHED
; as it runs. The high byte of each is incremented after every 256-byte page
; (INC csrc+2 / INC cdst+2 write into the instruction's own operand), so the
; single LDA/STA pair walks through all 15 pages without needing a pointer.
; ----------------------------------------------------------------------------
ORG &0A70
.copier
    LDA #&50 : STA csrc+2       ; source page  (&5000, staged in screen RAM)
    LDA #&0E : STA cdst+2       ; dest page    (&0E00, freed by *TAPE)
    LDY #15                     ; 15 pages = 3840 bytes covers the engine
    LDX #0
.cloop
.csrc LDA &5000,X              ; operand high byte is patched per page
.cdst STA &0E00,X              ; operand high byte is patched per page
    INX
    BNE cloop                  ; inner loop: 256 bytes of the current page
    INC csrc+2                 ; next page: bump both addresses...
    INC cdst+2
    DEY
    BNE cloop                  ; ...for 15 pages
    RTS
.copier_end
SAVE "COPY", copier, copier_end

; --- user-defined characters 224-251, loaded straight into the UDG page ---
ORG &0C00
.udg
    EQUB 202,106,106,106,110,126,126,60      ; 224 sea grass
    EQUB 10,82,84,68,36,177,155,218          ; 225 sea grass
    EQUB 80,74,42,34,36,141,217,219          ; 226 sea grass
    EQUB 146,84,84,40,170,170,108,16         ; 227 coral
    EQUB 165,66,66,24,102,255,66,129         ; 228 crab
    EQUB 5,5,0,27,127,224,137,37             ; 229 shrimp
    EQUB 0,0,0,0,0,128,240,126               ; 230 boat
    EQUB 0,3,15,24,48,112,240,15             ; 231
    EQUB 0,252,254,66,66,130,130,254         ; 232
    EQUB 127,39,57,62,31,31,15,15            ; 233
    EQUB 224,255,255,63,195,252,255,255      ; 234
    EQUB 126,128,255,255,255,255,0,255       ; 235
    EQUB 240,0,240,240,240,248,24,248        ; 236
    EQUB 0,0,120,253,255,252,120,0           ; 237 oxygen tank
    EQUB 108,254,254,254,254,124,56,16       ; 238 heart
    EQUB 0,4,32,0,17,4,0,64                  ; 239 bleed
    EQUB 0,0,0,0,0,0,0,0                     ; 240 unused
    EQUB 16,24,188,251,254,188,24,8          ; 241 fish
    EQUB 90,165,66,153,36,219,165,60         ; 242 seabed texture
    EQUB 165,90,219,36,153,66,60,165         ; 243
    EQUB 219,60,165,90,66,153,36,219         ; 244
    EQUB 60,153,90,219,165,36,66,90          ; 245
    EQUB 153,219,36,165,90,60,219,66         ; 246
    EQUB 36,66,153,60,219,165,90,153         ; 247
    EQUB 66,66,126,126,126,126,126,126       ; 248 junk
    EQUB 8,24,56,126,255,62,28,8             ; 249 junk
    EQUB 120,252,255,255,255,252,120,0       ; 250 junk
    EQUB 102,153,153,126,126,153,153,102     ; 251 junk
.udg_end
SAVE "UDG", udg, udg_end

; --- sea-bed critter sprites, MODE 2 plotshape format ---------------------
; Generated from the crab/shrimp UDGs with their level colours baked in, so
; the critter can be drawn by plotshape instead of the OS graphics-cursor
; character path, which cost a whole frame per tick.
ORG &0A30
.critspr
    ; crab, colour 1 - 4 byte-columns x 8 scanlines
    EQUB 2,1,1,0,1,3,1,2
    EQUB 2,0,0,1,2,3,0,0
    EQUB 1,0,0,2,1,3,0,0
    EQUB 1,2,2,0,2,3,2,1
    ; shrimp, colour 5 - 4 byte-columns x 8 scanlines
    EQUB 0,0,0,0,17,51,34,0
    EQUB 0,0,0,17,51,34,0,34
    EQUB 17,17,0,34,51,0,34,17
    EQUB 17,17,0,51,51,0,17,17
.critspr_end
SAVE "CRIT", critspr, critspr_end
