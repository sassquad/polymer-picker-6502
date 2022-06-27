REM Polymer picker loader
HIMEM=&2C00
MODE7:VDU23;8202;0;0;0;
PROCcntr(1,6,1,"Polymer Picker")
PROCcntr(0,6,2,"by Stephen Scott (c) 2021-22")
PROCcntr(0,6,3,"Thanks to ChrisB, jms2 and lurkio")
PRINT'"  The oceans are full of junk. Try and   help clean them up! Swim and collect"
PRINT " it all, before the local sealife eats   it and dies!"
PRINT'"  You have a limited air supply, which   decreases gradually as you swim. If"
PRINT " you swim faster, this will decrease     more quickly."
PRINT'"  You have one chance to refill your     air, by floating underneath your"
PRINT " boat, but only when you have 50% or     less. Use it wisely!":*FX15,0
PRINTTAB(4,23);CHR$129;CHR$(157);CHR$135;"PRESS SPACEBAR TO CONTINUE  ";CHR$156;:VDU28,0,22,39,6
REPEATUNTILGET=32:CLS:*FX15,0
PRINT'"  Try to avoid the shark, which will     come slowly towards you initially, but"
PRINT " will be more persistent if it injures   you!"
PRINT'"  Once you have collected all the junk   you will proceed to the next bay."
PRINT'"  Controls:     Z - swim left"
PRINT "                X - swim right"
PRINT "              */"" - swim up"
PRINT "                ? - swim down"
PRINT "     Return/Enter - swim faster"
REPEATUNTILGET=32:VDU26,12
PROCchars:PROCenv
PROCassemble(&900,2):W%=plotshape:R%=getaddr:Q%=check
PAGE=&1100:HIMEM=&2C00:CHAIN"Poly2"
END
DEFPROCcntr(D%,C%,Y%,msg$)
X%=(40-LEN(msg$))/2:msg$=CHR$(128+C%)+msg$
IFD%=1 FORN%=0TO1:PRINTTAB(X%-2,Y%+N%)CHR$141msg$:NEXT:ENDPROC
PRINTTAB(X%-1,Y%+N%)msg$:ENDPROC
DEFPROCchars
REM sea grass
VDU23,224,202,106,106,106,110,126,126,60
VDU23,225,10,82,84,68,36,177,155,218
VDU23,226,80,74,42,34,36,141,217,219
REM coral
VDU23,227,146,84,84,40,170,170,108,16
REM crab
VDU23,228,165,66,66,24,102,255,66,129
REM shrimp
VDU23,229,5,5,0,27,127,224,137,37
REM boat
VDU23,230,0,0,0,0,0,128,240,126
VDU23,231,0,3,15,24,48,112,240,15
VDU23,232,0,252,254,66,66,130,130,254
VDU23,233,127,39,57,62,31,31,15,15
VDU23,234,224,255,255,63,195,252,255,255
VDU23,235,126,128,255,255,255,255,0,255
VDU23,236,240,0,240,240,240,248,24,248
REM fish
VDU23,240,8,24,61,223,127,61,24,8
VDU23,241,16,24,188,251,254,188,24,8
VDU23,250,0,126,126,126,126,126,126,0
VDU23,254,0,0,8,32,4,16,0,0
VDU23,255,1,0,32,8,0,64,0,1
ENDPROC
DEFPROCenv
REM Collect
ENVELOPE1,1,1,1,1,1,1,1,0,0,0,-5,120,120
REM Bell
ENVELOPE2,1,0,0,0,50,25,25,127,-1,-1,-1,126,90
REM Bubbles
ENVELOPE3,5,15,0,0,72,0,0,-6,127,0,-9,0,126
REM Breathing
ENVELOPE4,129,0,-10,-1,1,0,2,6,-1,0,-1,126,74
REM Replenish air
ENVELOPE5,1,0,0,0,50,25,25,127,-1,-1,-1,126,90
ENDPROC
DEFPROCassemble(origin,maxpass)
P%=&70
[OPT 0
.addr
EQUW 0\&70-71
.top
EQUW &3000\&72-73
.rowcounter
EQUB 0\&74
.counter
EQUB 0\&75
.temp
EQUB 0\&76
.temp1
EQUB 0\&77
.depth
EQUB 0\&78
.shape
EQUW 0\&79-7A
.offset
EQUB 0\&7B
.shapeloaddr
EQUD 0:EQUW 0
.shapehiaddr
EQUD 0:EQUW 0
.shapesize
EQUD 0:EQUW 0
.shapedepth
EQUD 0:EQUW 0
]
shapes=&2C00
REM PRINT"Loading sprites at &";~shapes
FOR I%=0TO5:READfilename$:REM PRINT"Sprite ";filename$
OSCLI("LOAD "+filename$+" "+STR$~shapes)
I%?shapeloaddr=shapes AND&FF
I%?shapehiaddr=shapes DIV256
READ I%?shapesize,I%?shapedepth
shapes=shapes+I%?shapedepth*I%?shapesize
NEXT
DATA LDIVER,12,16,RDIVER,12,16,LFISH,4,8,RFISH,4,8,LSHK,16,16,RSHK,16,16
REM PRINT"Sprites loaded, next free byte=&";~shapes
FOR pass=0 TO maxpass STEP maxpass
P%=origin
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
REM PRINT"Press space to load game":REPEAT UNTIL INKEY-99
ENDPROC
