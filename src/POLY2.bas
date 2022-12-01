REM Polymer Picker loader
REM by Stephen Scott (c) 2022
REM Thanks to ChrisB, jms2, lurkio, TobyLobster and fizgog
REM Hi to the Stardot community
HIMEM=&2C00
FORT%=&900 TO &AFF STEP4:!T%=0:NEXT
PROCassemble:W%=plotshape:Q%=check
*LOAD SPRITES
PAGE=&1100:HIMEM=&2C00
CHAIN"Poly1":END
DEFPROCassemble
P%=&70
[OPT 0
.addr:EQUW 0\&70-71
.top:EQUW &3000\&72-73
.notrowcounter:EQUB 0\&74 \ unused
.counter:EQUB 0\&75
.temp:EQUB 0\&76
.temp1:EQUB 0\&77
.depth:EQUB 0\&78
.notshape:EQUW 0\&79-7A \ unused
.offset:EQUB 0\&7B
.shapeloaddr:EQUD 0:EQUW 0:EQUW 0
.shapehiaddr:EQUD 0:EQUW 0:EQUW 0
.shapesize:EQUD 0:EQUW 0:EQUW 0
.shapedepth:EQUD 0:EQUW 0:EQUW 0
]
shapes=&2C00
FORI%=0TO7
READ filename$
I%?shapeloaddr=shapes AND&FF
I%?shapehiaddr=shapes DIV256
READ I%?shapesize,I%?shapedepth
shapes=shapes+I%?shapedepth*I%?shapesize
NEXT
DATA LDIVER,12,16,RDIVER,12,16
DATA LFISH,4,8,RFISH,4,8
DATA LSHK,16,16,RSHK,16,16
DATA DLFISH,4,8,DRFISH,4,8
rowhi=&D01
FOR pass=0 TO 2 STEP 2
P%=&900
[OPT pass
.plotshape
PHA

\getaddr
TYA
AND #7:EOR #7:STA tmpa+1
TYA:EOR #&F8
LSR A:LSR A:LSR A
TAY
LSR A:LDA #0:ROR A
STA tmpb+1
LDA rowhi,Y
TAY
TXA
ASL A:ASL A
BCC skip1
INY:INY
.skip1 ASL A:BCC skip2:INY
.skip2 CLC
.tmpb ADC #&EE
.tmpa ORA #&EE
STA addr
BCC skip3
INY
.skip3 STY addr+1

PLA:TAY
LDA shapeloaddr,Y:STA shape+1
LDA shapehiaddr,Y:STA shape+2
LDA shapesize,Y:STA counter
LDA shapedepth,Y:STA depth
.label
LDY #&00:LDA addr+1:PHA:LDA addr:PHA
LDA depth:STA rowcounter+1:LDA addr:TAX:AND #&07
TAY:TXA:AND #&F8:STA addr
LDX #0
.innerloop
.shape LDA &EEEE,X:inx
EOR (addr),Y:STA (addr),Y:INY
CPY #&08:BEQ block
.noblock
.rowcounter CPX #&EE:BNE innerloop
.nextblock
LDA shape+1:CLC:ADC depth:STA shape+1:BCC nohi:INC shape+2
.nohi
CLC:PLA:ADC #&08:STA addr:PLA:ADC #&00
STA addr+1:DEC counter:BNE label
RTS
.block
LDY #&00:LDA addr:CLC:ADC #&80:STA addr
LDA addr+1:ADC #&02:BPL noboundary:SEC:SBC #&50
.noboundary
STA addr+1:BNE noblock
.check
STX &AB0:STY &AB1:LDY #7
.checkloop
LDA &AE0,Y\BX:CMP &AB0:BCS notinbox\BX>CX
CLC:ADC #8\BW%:CMP &AB0:BCC notinbox\BX<CX
LDA &AE8,Y:CMP &AB1:BCC notinbox\BY<CY
SEC:SBC #8\BH%:CMP &AB1:BCC checkfinish\BY>CY - inverted check
.notinbox
DEY:BPL checkloop
.checkfinish
STY &AB2:RTS
]
NEXTpass
ENDPROC
