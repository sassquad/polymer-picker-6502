REM Polymer Picker loader
REM by Stephen Scott (c) 2022
REM Thanks to ChrisB, jms2, lurkio, TobyLobster and fizgog
REM Hi to the Stardot community
HIMEM=&2B00:PROCinit:PROCchars:PROCenv
PRINTTAB(5,30)"  Press SPACEBAR to continue  ":*FX15
REPEATUNTILGET=32
MODE7:VDU23;8202;0;0;0;
PROCask
*LOAD POLY3 3000
*LOAD POLY4 5000
REPEAT
A$=GET$
UNTIL A$=" " OR A$="I" OR A$="R":VDU26,12
IF A$=" ":PROCstart
IF A$="R":PROCredefine:VDU26,12:PROCstart
IF A$="I":PROCinstruct
REPEAT
A$=GET$
UNTIL A$=" " OR A$="R":VDU26,12
IF A$=" ":PROCstart
IF A$="R":PROCredefine:VDU26,12:PROCstart
END
DEFPROCstart
REM Write key definitions into &100
FOR X%=0 TO 4
X%?&100=k%(X%)
NEXT:VDU26,12,21
P%=&50:[OPT2:ldx#0:ldy#&18:lda&4700,X:sta&2500,X:inx:bne&54:dec&56:dec&59:dey:bpl&54:rts:]
*TAPE
A$="CALL&50"+CHR$13+"OLD"+CHR$13+"PAGE=&5000:GOTO1"+CHR$13
A%=138:X%=0:FOR E%=1TOLENA$:Y%=ASCMID$(A$,E%,1):CALL&FFF4:NEXT
PAGE=&E00:END
ENDPROC
DEFPROCask
PROCcntr(1,6,1,"Polymer Picker v1.12xmas")
PROCcntr(0,6,1,"Written by Stephen Scott (c) 2024")
PROCcntr(0,12,2,"www.sassquad.net")
PROCcntr(0,9,3,"Bluesky: @sassquad.net")
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
PROCcntr(1,6,1,"Polymer Picker v1.12xmas")
PROCcntr(0,6,1,"Written by Stephen Scott (c) 2024")
PROCcntr(0,12,2,"www.sassquad.net")
PROCcntr(0,9,3,"Bluesky: @sassquad.net")
PRINT''" The Arctic Ocean is polluted with"
PRINT "discarded Christmas plastic. Your job"
PRINT "is to try and clean it up. Swim and"
PRINT "collect the festive junk before the"
PRINT "local sealife eat them and perish!"
PRINT''" To collect an item, move until your"
PRINT "hand is touching it. The item will then"
PRINT "be collected. All items are white"
PRINT "coloured."
VDU31,4,22,129,157,135:PRINT;"PRESS SPACEBAR TO CONTINUE  ";:VDU156,28,0,21,39,6
*FX15
REPEATUNTILGET=32:CLS
PRINT''" You have a limited air supply, which"
PRINT "decreases more quickly if you swim"
PRINT "faster. Spare tanks will appear under"
PRINT "your boat when your remaining air"
PRINT "reaches 50%."
PRINT''" Try to avoid the shark, it will"
PRINT "bite you, which reduces your air. The"
PRINT "jellyfish also have quite a sting!"
*FX15
REPEATUNTILGET=32:CLS
PRINT''" Once you have collected all the junk"
PRINT "you will proceed to the next bay."
PRINT "Bonus points are awarded for each fish"
PRINT "left alive, plus any air left."
PRINT''" As you progress, fish on later levels"
PRINT "will hurt you, and... well, let's just"
PRINT "say Nature in the Arctic is cruel!"
PRINT''" Good luck, and Merry Christmas!"
*FX15
REPEATUNTILGET=32:CLS
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
DIM k%(4):k%(0)=97:k%(1)=66:k%(2)=72:k%(3)=104:k%(4)=73:s$="Swim "
DIM k$(4):k$(0)=s$+"left":k$(1)=s$+"right":k$(2)=s$+"up":k$(3)=s$+"down":k$(4)=s$+"faster"
REM Find key lookup table
A%=&AC:X%=0:Y%=255:T%=((USR(&FFF4)DIV256)AND&FFFF)-1
ENDPROC
DEFPROCchars
VDU23,224,202,106,106,106,110,126,126,60,23,225,10,82,84,68,36,177,155,218,23,226,80,74,42,34,36,141,217,219:REM sea grass
VDU23,252,0,24,60,24,60,126,60,126,23,253,60,126,255,24,24,126,60,60:REM tree
VDU23,227,146,84,84,40,170,170,108,16:REM coral
VDU23,228,12,14,30,13,92,156,254,126:REM santa
VDU23,229,208,96,224,254,126,124,148,162:REM reindeer
REM boat
VDU23,230,0,0,0,0,0,128,240,126,23,231,0,3,15,24,48,112,240,15,23,232,0,-4,-2,66,66,130,130,-2
VDU23,233,127,39,57,62,31,31,15,15,23,234,224,-1,-1,63,195,-4,-1,-1,23,235,126,128,-1,-1,-1,-1,0,-1,23,236,240,0,240,240,240,-8,24,-8
VDU23,237,0,0,120,-3,-1,-4,120,0:REM oxygen tank
VDU23,238,108,-2,-2,-2,-2,124,56,16:REM heart
VDU23,239,0,4,32,0,17,4,0,64:REM bleed
VDU23,241,16,24,188,-5,-2,188,24,8:REM fish
FORT=242TO247:VDU23,T:FORI=1TO8:VDURND(255):NEXT:NEXT
VDU23,248,16,56,124,246,250,254,124,16
VDU23,249,0,7,119,37,127,127,213,42,0
VDU23,250,0,102,102,255,255,255,255,0
VDU23,251,24,24,126,90,24,36,36,102
ENDPROC
DEFPROCenv
ENVELOPE1,1,0,0,0,30,25,25,127,-1,-1,-1,126,90
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
DEFPROCredefine:S%=FALSE:VDU26,12
PROCcntr(1,6,1,"Polymer Picker v1.12xmas")
PROCcntr(0,6,1,"Written by Stephen Scott (c) 2024")
PROCcntr(0,12,2,"www.sassquad.net")
PROCcntr(0,9,3,"Bluesky: @sassquad.net")
VDU28,0,21,39,6
REPEAT:VDU12:PRINT''"Enter your preferred gameplay keys."
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
