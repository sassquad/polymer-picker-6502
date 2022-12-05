REM Polymer Picker loader
REM by Stephen Scott (c) 2022
REM Thanks to ChrisB, jms2, lurkio, TobyLobster and fizgog
REM Hi to the Stardot community
HIMEM=&2B00
PROCinit:PROCchars
PROCenv
PRINTTAB(5,30)"  Press SPACEBAR to continue  ":*FX15
REPEATUNTILGET=32
MODE7:VDU23;8202;0;0;0;
PROCask
*LOAD POLY3 3000
*LOAD POLY4 5000
REPEAT
A$=GET$
UNTIL A$=" " OR A$="I" OR A$="R"
IF A$=" " THEN VDU26,12:PROCstart
IF A$="R" THEN VDU26,12:PROCredefine:VDU26,12:PROCstart
IF A$="I" THEN VDU26,12:PROCinstruct
REPEAT
A$=GET$
UNTIL A$=" " OR A$="R"
IF A$=" " THEN VDU26,12:PROCstart
IF A$="R" THEN VDU26,12:PROCredefine:VDU26,12:PROCstart
END
DEFPROCstart
REM Write key definitions into &100
FOR X%=0 TO 4
X%?&100=k%(X%)
NEXT:VDU26,12,21
P%=&50:[OPT2:ldx#0:ldy#&1D:lda&4D00,X:sta&2B00,X:inx:bne&54:dec&56:dec&59:dey:bpl&54:rts:]
*TAPE
A$="CALL&50"+CHR$13+"OLD"+CHR$13+"PAGE=&5000:GOTO1"+CHR$13
A%=138:X%=0:FOR E%=1TOLENA$:Y%=ASCMID$(A$,E%,1):CALL&FFF4:NEXT
PAGE=&E00:END
ENDPROC
DEFPROCask
PROCcntr(1,6,1,"Polymer Picker")
PROCcntr(0,6,1,"Written by Stephen Scott (c) 2022")
PROCcntr(0,6,2,"w: sassquad.net / t: @sassquad")
PROCcntr(0,3,5,"with the grateful assistance of")
PROCcntr(0,3,6,"Stardot community forum members")
PROCcntr(0,3,7,"ChrisB, jms2, lurkio, TobyLobster,")
PROCcntr(0,3,8,"hexwab and fizgog!")
PROCcntr(0,2,10,"Press I to view the instructions")
PROCcntr(0,2,12,"or R to redefine the controls")
VDU26,31,2,22,129,157,135:PRINT;"OR PRESS SPACEBAR TO PLAY GAME  ";:VDU156,28,0,21,39,6
*FX15
ENDPROC
DEFPROCinstruct
PROCcntr(1,6,1,"Polymer Picker")
PROCcntr(0,6,1,"Written by Stephen Scott (c) 2022")
PROCcntr(0,6,2,"w: sassquad.net / t: @sassquad")
PRINT''" Your local tropical bay is polluted"
PRINT "with discarded plastic. Your job is to"
PRINT "try and clean it up. Swim and collect"
PRINT "the junk, before the local sealife eats"
PRINT "it and dies!"
PRINT''" To collect an item, move until your"
PRINT "hand is touching it. The item will then"
PRINT "be collected. All items are white"
PRINT "coloured."
VDU31,4,22,129,157,135:PRINT;"PRESS SPACEBAR TO CONTINUE  ";:VDU156,28,0,21,39,6
*FX15
REPEATUNTILGET=32:VDU12
PRINT''" You have a limited air supply, which"
PRINT "decreases more quickly if you swim"
PRINT "faster. A spare tank will appear under"
PRINT "your boat when your remaining air"
PRINT "reaches 50%. Use it wisely!"
PRINT''" Try to avoid the shark, which will"
PRINT "come slowly towards you initially, but"
PRINT "don't let him bite you!"
*FX15
REPEATUNTILGET=32:VDU12
PRINT''" Once you have collected all the junk"
PRINT "you will proceed to the next bay."
PRINT "Bonus cash is awarded for each fish"
PRINT "remaining alive, in addition to any"
PRINT "remaining air left."
PRINT''" As you progress, fish on later levels"
PRINT "will hurt you, and... well, let's just"
PRINT "say Nature is cruel!"
*FX15
REPEATUNTILGET=32:VDU12
PRINT''" Controls:"
PRINT'"               Z - swim left"
PRINT "               X - swim right"
PRINT "             */"" - swim up"
PRINT "               ? - swim down"
PRINT "    Return/Enter - swim faster"
PRINT'"             S/Q - Sound on/off"
PRINT "             P/U - Pause/unpause"
VDU26,31,4,22,129,157,135:PRINT;"PRESS SPACEBAR TO PLAY GAME  ";:VDU156
VDU31,2,23,129,157,135:PRINT;"OR PRESS R TO REDEFINE CONTROLS  ";:VDU156
VDU28,0,21,39,6
*FX15
ENDPROC
DEFPROCcntr(D%,C%,Y%,msg$)
X%=(40-LEN(msg$))/2:msg$=CHR$(128+C%)+msg$
IFD%=1 FORN%=0TO1:VDU31,X%-2,Y%+N%,141:PRINT;msg$:NEXT:ENDPROC
VDU31,X%-1,Y%+N%:PRINT;msg$:ENDPROC
DEFPROCinit
DIM k%(4)
k%(0)=97:REM Z Left
k%(1)=66:REM X Right
k%(2)=72:REM */"" Up
k%(3)=104:REM ? Down
k%(4)=73:REM Return Swim faster
REM 
DIM k$(4)
k$(0)="Swim left"
k$(1)="Swim right"
k$(2)="Swim up"
k$(3)="Swim down"
k$(4)="Swim faster"
REM Find key lookup table
A%=&AC:X%=0:Y%=255
T%=((USR(&FFF4)DIV256)AND&FFFF)-1
ENDPROC
DEFPROCchars
REM sea grass
VDU23,224,202,106,106,106,110,126,126,60
VDU23,225,10,82,84,68,36,177,155,218
VDU23,226,80,74,42,34,36,141,217,219
REM coral
VDU23,227,146,84,84,40,170,170,108,16
REM crab
VDU23,228,165,66,66,24,102,-1,66,129
REM shrimp
VDU23,229,5,5,0,27,127,224,137,37
REM boat
VDU23,230,0,0,0,0,0,128,240,126
VDU23,231,0,3,15,24,48,112,240,15
VDU23,232,0,-4,-2,66,66,130,130,-2
VDU23,233,127,39,57,62,31,31,15,15
VDU23,234,224,-1,-1,63,195,-4,-1,-1
VDU23,235,126,128,-1,-1,-1,-1,0,-1
VDU23,236,240,0,240,240,240,-8,24,-8
REM oxygen tank
VDU23,237,0,0,120,-3,-1,-4,120,0
REM heart
VDU23,238,108,-2,-2,-2,-2,124,56,16
REM fish
VDU23,241,16,24,188,-5,-2,188,24,8
ENDPROC
DEFPROCenv
ENVELOPE1,1,0,0,0,50,25,25,127,-1,-1,-1,126,90
ENVELOPE2,3,-1,0,0,246,0,0,0,0,-1,-3,120,120
ENVELOPE3,5,15,0,0,72,0,0,-6,127,0,-9,0,126
ENVELOPE4,129,0,-10,-1,1,0,2,6,-1,0,-1,126,74
ENDPROC
DEFFNgetkey
A%=122
REPEATUNTIL(USR(&FFF4)AND&FF00)=&FF00
REPEAT
G%=TRUE
K%=-1
IF INKEY(-1) THEN K%=0
IF INKEY(-2) THEN K%=1
IF K%=-1 THEN K%=(USR(&FFF4)AND&FF00)DIV256
IF K%=32 OR K%=113 OR K%=55 OR K%=53 OR K%=81 OR K%=16 THEN G%=FALSE:VDU 7
FOR B%=0 TO 4
IF k%(B%)=K% THEN G%=FALSE
NEXT
UNTIL K%<>255 AND K%<>112 AND G%=TRUE
=K%
DEFPROCredefine
S%=FALSE
VDU26,12
PROCcntr(1,6,1,"Polymer Picker")
PROCcntr(0,6,1,"Written by Stephen Scott (c) 2022")
PROCcntr(0,6,2,"w: sassquad.net / t: @sassquad")
VDU28,0,21,39,6
REPEAT
VDU12
PRINT''"Enter your preferred gameplay keys."
PRINT'"Note that S,Q,P and U are reserved."
PRINT
FOR Z%=0 TO 4
k%(Z%)=-1
NEXT
FOR Z%=0 TO 4
PRINTTAB(5);CHR$(131);k$(Z%);" - ";
k%(Z%)=FNgetkey
PRINT FNkey(k%(Z%))
NEXT
PRINT''TAB(4);CHR$(130);CHR$(136);"Keys OK?"
*FX 21,0
N$=GET$
IF N$="Y" OR N$="y" THEN S%=TRUE
UNTIL S%=TRUE
ENDPROC
DEFFNkey(K%)
LOCAL k$
IF K%=0 THEN k$="Shift"
IF K%=1 THEN k$="Ctrl"
I%=-1
A%=5:X%=&14:Y%=4:E%=T%+K%:F%=0:CALL&FFF1
RESTORE
IF k$="" THEN REPEAT:READ I%,k$:UNTIL F%=I% OR I%=256
IF I%=256 THEN k$=CHR$(F%)
=k$
DATA 0,"Tab",1,"Caps Lock",2,"Shift Lock",13,"Return",32,"Space",127,"Delete"
DATA 130,"f2",131,"f3",132,"f4",132,"f5",133,"f6",134,"f7",135,"f8",136,"f9"
DATA 139,"Copy",140,"Left",141,"Right",142,"Down",143,"Up",256,""
