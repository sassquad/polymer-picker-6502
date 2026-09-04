PUTTEXT "src/BOOT.txt", "!BOOT",&FFFFFF,&FFFFFF
PUTBASIC "src/POLYSCR.bas","POLYSCR"
PUTFILE "src/PPBY.bin","PPBY",&FF1800,&FF1800
PUTFILE "src/PPSCR.bin","PPSCR",&FF3000,&FF3000
PUTBASIC "src/POLY1.bas","POLY1"
PUTBASIC "src/POLY3.bas","POLY3"

; COPY (engine relocator) and UDG (character definitions)
INCLUDE "src/support.asm"

ORG &2B00
.sprites_start
INCBIN "src/LDIVER.bin"
INCBIN "src/RDIVER.bin"
INCBIN "src/LFISH.bin"
INCBIN "src/RFISH.bin"
INCBIN "src/LSHK.bin"
INCBIN "src/RSHK.bin"
INCBIN "src/DLFISH.bin"
INCBIN "src/DRFISH.bin"
INCBIN "src/FSHK.bin"
INCBIN "src/JELLY.bin"
.sprites_end
SAVE "SPRITES", sprites_start, sprites_end

; GFX (plotshape/check at &900) and the machine-code engine (&0E00)
INCLUDE "src/engine.asm"
