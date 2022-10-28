REM Polymer Picker loader
REM by Stephen Scott (c) 2021-22
REM Thanks to ChrisB, jms2, lurkio and TonyLobster
REM Hi to the Stardot community
HIMEM=&2BFF
FORT%=&900 TO &AFF STEP4:!T%=0:NEXT
PROCenv:PROCassemble:W%=plotshape:R%=getaddr:Q%=check
PAGE=&1100:HIMEM=&2BFF:CHAIN"Poly3":END
DEFPROCenv
ENVELOPE1,1,1,1,1,1,1,1,0,0,0,-5,120,120
ENVELOPE2,3,-1,0,0,246,0,0,0,0,-1,-3,120,120
ENVELOPE3,5,15,0,0,72,0,0,-6,127,0,-9,0,126
ENVELOPE4,129,0,-10,-1,1,0,2,6,-1,0,-1,126,74
ENVELOPE5,1,0,0,0,50,25,25,127,-1,-1,-1,126,90
ENVELOPE6,1,0,0,0,0,0,0,120,0,0,-1,100,100
ENDPROC
DEFPROCassemble
P%=&70
[OPT 0
.addr:EQUW 0\&70-71
.top:EQUW &3000\&72-73
.rowcounter:EQUB 0\&74
.counter:EQUB 0\&75
.temp:EQUB 0\&76
.temp1:EQUB 0\&77
.depth:EQUB 0\&78
.shape:EQUW 0\&79-7A
.offset:EQUB 0\&7B
.shapeloaddr:EQUD 0:EQUW 0:EQUW 0
.shapehiaddr:EQUD 0:EQUW 0:EQUW 0
.shapesize:EQUD 0:EQUW 0:EQUW 0
.shapedepth:EQUD 0:EQUW 0:EQUW 0
]
shapes=&2BFF
FORI%=0TO7
READ filename$
OSCLI("LOAD "+filename$+" "+STR$~shapes)
I%?shapeloaddr=shapes AND&FF
I%?shapehiaddr=shapes DIV256
READ I%?shapesize,I%?shapedepth
shapes=shapes+I%?shapedepth*I%?shapesize
NEXT
DATA LDIVER,12,16,RDIVER,12,16
DATA LFISH,4,8,RFISH,4,8
DATA LSHK,16,16,RSHK,16,16
DATA DLFISH,4,8,DRFISH,4,8
FOR pass=0 TO 2 STEP 2
P%=&A00
[OPT pass
.getaddr
LDA #&00:STA addr+1:TYA:EOR #&FF
PHA:LSR A:LSR A:LSR A:TAY:LSR A:STA temp
LDA #&00:ROR A:ADC top:PHP:STA addr:TYA
ASL A:ADC temp:PLP:ADC top+1
STA addr+1:LDA #&00:STA temp:TXA
ASL A:ROL temp:ASL A:ROL temp:ASL A:ROL temp
ADC addr:STA addr:LDA temp:ADC addr+1:BPL ok
SEC:SBC #&50
.ok
STA addr+1:PLA:AND #&07:ORA addr:STA addr:RTS
.plotshape
PHA:JSR getaddr:PLA:TAY
LDA shapeloaddr,Y:STA shape
LDA shapehiaddr,Y:STA shape+1
LDA shapesize,Y:STA counter
LDA shapedepth,Y:STA depth
\fall through to 'doplot'
.doplot
LDA addr+1:BEQ return
.label
LDY #&00:LDA addr+1:PHA:LDA addr:PHA
LDA depth:STA rowcounter:LDA addr:AND #&07
STA offset:LDA addr:AND #&F8:STA addr
.innerloop
LDA (shape),Y:INY:STY temp
LDY offset:EOR (addr),Y:STA (addr),Y:INY
CPY #&08:BEQ block
.noblock
STY offset:LDY temp:DEC rowcounter:BNE innerloop
.nextblock
LDA shape:CLC:ADC depth:STA shape:BCC nohi:INC shape+1
.nohi
CLC:PLA:ADC #&08:STA addr:PLA:ADC #&00
BPL nobound1:SEC:SBC #&50
.nobound1
STA addr+1:DEC counter:BNE label
.return
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
