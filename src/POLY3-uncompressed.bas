*FX3
IFPAGE<>&E00:PROCr
N%=RND(-TIME):PROCinit:S%=0:MODE7:VDU23;8202;0;0;0;:HIMEM=&2BFF:PROChisc:S%=0:MODE2:VDU23;8202;0;0;0;:HIMEM=&2BFF:REPEAT:REPEAT:PROCoff:PROCsc:PROCstart:PROCboat:PROCon:IFlev%>8:PROCf:PROCs:ELSEIF(lev%MOD2)=1:PROCf ELSE PROCs
PROCbags:PROCstat:PROCscore:PROCairbar:TIME=0:REPEAT:PROCdiver:PROCair:IFlev%>8:PROCmf:PROCms:ELSEIF(lev%MOD2)=1:PROCmf ELSE PROCms
PROCmsl:UNTIL P%=0 OR L%=0 OR O%<928:IFP%=0 AND O%>927 PROCgreat:lev%=lev%+1
UNTIL L%=0 OR O%<928:PROCover:UNTIL0
DEFPROCinit:FX%=&AB8:FY%=&AC0:FH%=&AC8:FV%=&AD0:F%=&AD8:BX%=&AE0:BY%=&AE8:lev%=1:DIMhs%(10),hs$(10):FORT%=1TO10:hs%(T%)=(11-T%)*500:hs$(T%)="POLYMER-PICKER":NEXT:ENDPROC
DEFPROCoff:VDU4,12:FORZ=0TO15:VDU19,Z,0;0;:NEXT:M$="GET READY!":IFlev%>4:M$="OH BOY...!":IFlev%>8:M$="AAAAAAAGH!"
VDU19,14,7;0;17,14,31,5,15:PRINT;M$;:PROCt:ENDPROC
DEFPROCon:VDU4,17,128,31,5,15:PRINTSPC(10):FORZ=0TO15:VDU19,Z,Z;0;:NEXT:VDU19,0,4;0;19,15,0;0;19,14,6;0;5:READo%,p%:VDU19,8,o%;0;19,9,p%;0;:ENDPROC
DEFPROCsc:da%=103+(lev%MOD4):RESTOREda%:READco%:VDU28,0,4,19,0,17,co%,12,26,5:READci%,mt%
IFci%=1:READc1%,c2%,c3%,c4%:PROCc(c1%,c2%,c3%,c4%)
IFci%=2:FORa=1TO2:READc1%,c2%,c3%,c4%:PROCc(c1%,c2%,c3%,c4%):NEXT
IFmt%=1:READc1%,c2%,c3%,c4%:PROCmt(c1%,c2%,c3%,c4%)
IFmt%>1:FORa=1TOmt%:READc1%,c2%,c3%,c4%:PROCmt(c1%,c2%,c3%,c4%):NEXT
VDU4,28,0,31,19,27,17,143,12,26,28,0,28,19,27,17,132,12,26,5:FORT%=242TO247:VDU23,T%:FORI%=1TO8:VDURND(255):NEXT,:FORy%=127TO160STEP32:FORx%=0TO1279STEP64:VDU18,0,3,25,4,x%;y%;RND(6)+241:NEXT,
FORG=0TO9:h=RND(2)+224:VDU18,0,15,25,4,(G*136)+8;224;h,10,8,224,18,0,2,25,4,G*136;224;h,10,8,224:NEXT
FORG=3TO6:VDU18,0,5,25,4,64+(G*136);192;227:NEXT:ENDPROC
DEFPROCstart:DX%=32:DY%=214:DZ%=1:PROCd(DZ%,DX%,DY%):BW%=7:BH%=7:V%=2:H%=1:P%=8:L%=8:O%=1224:OD%=300:SF%=1:DF%=1:OXY%=0:OXB%=0:IF(lev%MOD2)=1cr%=228:co%=1:ELSE:cr%=229:co%=5
crx%=FNgrx:VDU18,3,co%,25,4,crx%;192;cr%:ENDPROC
DEFPROCboat:VDU18,0,15,25,4,512;920;230,231,232,10,8,8,8,233,234,235,236,18,0,7,25,4,512;924;230,231,232,10,8,8,8,233,234,235,236:ENDPROC
DEFPROCf:FORA=0TO7:FX%?A=FNrx(1):FY%?A=FNry:FH%?A=3:F%?A=3:IFA>3:FH%?A=1:F%?A=2
FV%?A=8:PROCd(F%?A,FX%?A,FY%?A):NEXT:E%=0:ENDPROC
DEFPROCs:SD%=4:SX%=FNrx(4):SY%=60+(lev%*10):IFSY%>140:SY%=140
IFSX%<=(DX%+12):SD%=5
PROCd(SD%,SX%,SY%):ENDPROC
DEFPROCmf:IFFH%?E%=2ANDFY%?E%=0:E%=(E%+1)MOD8:ENDPROC
PROCd(F%?E%,FX%?E%,FY%?E%):FX%?E%=FX%?E%+FH%?E%-2:FY%?E%=FY%?E%+FV%?E%-6
IFFX%?E%<4:FH%?E%=3:F%?E%=3
IFFX%?E%>75:FH%?E%=1:F%?E%=2
IFFY%?E%<64ANDFH%?E%<>2 THEN FV%?E%=8 ELSE IF FY%?E%<48 AND FH%?E%=2 THEN FY%?E%=48
IFFY%?E%>200ANDFH%?E%<>2:FV%?E%=4
PROCd(F%?E%,FX%?E%,FY%?E%):IFFH%?E%<>0PROCfcheck((FX%?E%+3*(F%?E%-2))*2,FY%?E%-5,E%)
IFFH%?E%<>0:IFlev%>4:IFFNbite(FX%?E%,FY%?E%):PROChurt
E%=(E%+1)MOD8:ENDPROC
DEFPROCms:OSX%=SX%:OSY%=SY%:OSD%=SD%
IF(SX%+8)<(DX%+6)ANDSX%<62:SX%=SX%+SF%:SD%=5
IF(SX%+6)>(DX%+6)ANDSX%>1:SX%=SX%-SF%:SD%=4
IFSY%<DY%ANDSY%<194:SY%=SY%+SF%
IFSY%>DY%ANDSY%>64:SY%=SY%-SF%
PROCd(OSD%,OSX%,OSY%):PROCd(SD%,SX%,SY%):IFFNbite(SX%+8,SY%):PROChurt
ENDPROC
DEFPROCbags:VDU23,251:READa,b,c,d,e,f,g,h:VDUa,b,c,d,e,f,g,h:FORA=0TO7:BX%?A=(A+1)*16:BY%?A=((RND(153)-1)+48):VDU18,3,7,25,4,BX%?A*8;BY%?A*4;251:NEXT:ENDPROC
DEFPROCstat:VDU26,4,17,143,17,7,31,1,30,251,32,17,7:PRINT;P%:VDU31,6,30,17,6,241,32,17,7:PRINT;L%:VDU31,11,30:PRINT"Air":VDU17,128,5:ENDPROC
DEFPROCscore:VDU4,17,7,31,6,0:PRINT"$"STRING$(6-LENSTR$S%,"0");S%;:VDU5:ENDPROC
DEFPROCairbar:VDU5,18,0,14:MOVE920,40:MOVE1216,40:PLOT85,920,52:PLOT85,1216,52:ENDPROC
DEFPROCair:IFTIME<OD%ENDPROC
O%=O%-(8*DF%):SOUND0,4,6,3
IFO%>912:VDU18,0,15,25,4,O%;52;25,5,O%;40;25,4,O%+8;52;25,5,O%+8;40;
IFO%>999:VDU19,14,6;0; ELSE VDU19,14,9;0;
IFO%<1068:IFOXY%=0ANDOXB%=0:SOUND2,3,240,2:VDU18,3,6,25,4,612;850;237;:OXB%=1
TIME=0:ENDPROC
DEFPROCdiver:A%=DX%:B%=DY%:C%=DZ%
IFINKEY(-(?&100+1))AND DX%>1:DX%=DX%-DF%:DZ%=0
IFINKEY(-(?&101+1))AND DX%<67:DX%=DX%+DF%:DZ%=1
IFINKEY(-(?&102+1))AND DY%<212:DY%=DY%+(DF%*2)
IFINKEY(-(?&103+1))AND DY%>54:DY%=DY%-(DF%*2)
IFINKEY(-(?&104+1))AND (DX%<>A% OR DY%<>B%):DF%=2:OD%=100:PROCair:ELSE:DF%=1:OD%=200
PROCd(C%,A%,B%):PROCd(DZ%,DX%,DY%):CX%=DX%+6:CY%=DY%-14:PROCcheck(CX%*2,CY%):IFDX%>30:IFDX%<50:IFDY%>200:IFO%<1068:IFOXY%=0:PROCgotair
IFINKEY-56PROCp(7,29,"Paused"):REPEATUNTILINKEY-54:PROCp(7,29,"      ")
IFINKEY-17PROCp(5,31,"Quiet Mode"):*FX210,1
IFINKEY-82PROCp(5,31,"          "):*FX210,0
ENDPROC
DEFPROCp(x,y,S$):VDU4,17,143,17,7,31,x,y:PRINT;S$;:VDU5:ENDPROC
DEFPROCcheck(X%,Y%):C%=FNrc(X%,Y%):IFC%<8:SOUND1,1,99,1:PROCgot(C%)
PROCstat:ENDPROC
DEFPROCgot(c%):VDU18,3,7,25,4,BX%?C%*8;BY%?C%*4;251,4:P%=P%-1:S%=S%+200:BX%?C%=255:BY%?C%=255:PRINTTAB(13-LENSTR$S%,0);S%:ENDPROC
DEFFNbite(i%,j%):IFi%<DX% OR i%>(DX%+12) OR j%<(DY%-12) OR j%>DY%:=FALSE:ELSE:=TRUE
DEFPROCfcheck(X%,Y%,E%):C%=FNrc(X%,Y%):IFC%<8:PROCdeadfish(E%,C%)
ENDPROC
DEFPROCdeadfish(E%,C%):P%=P%-1:L%=L%-1:SOUND3,2,96,4:PROCd(F%?E%,FX%?E%,FY%?E%):F%?E%=F%?E%+4:PROCd(F%?E%,FX%?E%,FY%?E%):FH%?E%=2:FV%?E%=0:PROCstat:VDU18,3,7,25,4,BX%?C%*8;BY%?C%*4;251:BX%?C%=255:BY%?C%=255:ENDPROC
DEFPROCmsl:ocx%=crx%:crx%=crx%+6:IFcrx%>1260crx%=0
IFcrx%<>ocx%:VDU5,18,3,co%,25,4,ocx%;192;cr%,25,4,crx%;192;cr%
ENDPROC
DEFPROCgotair:O%=1224:SOUND1,1,80,1:PROCairbar:OXY%=1:OXB%=0:SF%=1:VDU18,3,6,25,4,612;850;237;:ENDPROC
DEFPROChurt:OD%=150:PROCair:SF%=2:SOUND0,-5,23,1:VDU18,3,1:FORz=1TO4:PLOT69,(DX%*16)+RND(64),(DY%*4)+RND(64):NEXT:ENDPROC
DEFPROCgreat:IFlev%>8:PROCbon:ELSE:IF(lev%MOD2)=1:PROCbon
VDU4,31,5,2:PRINT"NICE ONE!":TIME=0:REPEATUNTILTIME>300:TIME=0:VDU5:ENDPROC
DEFPROCbon:B=0:FORA=0TO7:IFFH%?A<>2ANDFY%?A<>0:SOUND2,1,(30+B*10),1:S%=S%+50:B=B+1:PROCscore:VDU18,0,1,25,4,FX%?A*16;(FY%?A*4)+40;238
FORz=1TO400:NEXT,:ENDPROC
DEFPROCover:SOUND3,2,96,4:TIME=0:REPEATUNTILTIME=200:VDU4,17,co%,12,31,5,15:PRINT"GAME  OVER":TIME=0:REPEATUNTILTIME=300:ENDPROC
DEFPROCc(h%,v%,r%,c%):VDU24,0;864;1279;1023;29,h%;v%;18,0,c%:x%=r%:y%=0:z%=x%/2
REPEAT:VDU25,4,x%;y%;25,5,-x%;y%;25,4,y%;x%;25,5,-y%;x%;25,4,x%;-y%;25,5,-x%;-y%;25,4,y%;-x%;25,5,-y%;-x%;:y%=y%+1:z%=z%-y%
IFz%<0:z%=z%+x%:x%=x%-1
UNTILx%<y%:ENDPROC
DEFPROCmt(mx%,LE%,HE%,CO%):ox%=-32:oy%=0:L=LE%/PI:VDU29,mx%;864;25,4,0;0;
FORx%=0TOLE%STEP64:y%=40+RND(40)+HE%*SIN(x%/L):VDU18,0,CO%,25,4,x%;y%;25,4,x%;0;:PLOT85,ox%,oy%:PLOT85,ox%,0:VDU18,0,15,25,4,ox%;oy%+4;25,5,x%;y%+4;:ox%=x%:oy%=y%:NEXT
VDU25,5,x%+16;4;18,0,CO%,25,4,ox%;0;25,4,ox%;oy%;:PLOT85,x%+16,0:ENDPROC
DEFPROCt:IFlev%>8:re%=102:ELSEIF(lev%MOD2)=1:re%=100 ELSE re%=101
RESTOREre%:chan%=1:FORu=1TO7:READnote,dur:dur=dur+2:SOUNDchan%,1,note,dur:FORT=1TO400:NEXT
chan%=chan%+1:IFchan%=4chan%=1
NEXT:ENDPROC
DEFPROCd(A%,X%,Y%):CALLW%:ENDPROC
DEFFNrx(W):W=W*4:=(RND(73-W)-1)+4
DEFFNry:=(RND(153)-1)+48
DEFFNrc(X%,Y%):CALLQ%:=?&AB2
DEFFNrs(X%,Y%):CALLR%:addr%=!&70 AND &FFFF:=?addr%
DEFFNgrx:=(RND(32)+2)*32
DEFFNgry:=(RND(33)+18)*16
DATA129,4,125,4,109,4,101,4,89,4,81,4,77,4
DATA77,4,81,4,89,4,101,4,109,4,125,4,129,4
DATA129,4,125,4,129,4,125,4,129,4,125,4,81,4
DATA131,1,2,40,860,40,5,864,120,32,1,980,200,64,1,6,7,66,66,126,126,126,126,126,126
DATA134,1,2,40,980,40,3,864,200,64,2,980,200,64,2,5,3,8,24,56,126,255,62,28,8
DATA133,1,2,40,860,40,1,864,180,32,15,980,200,64,15,5,3,120,-4,-1,-1,-1,-4,120,0
DATA143,2,2,100,920,40,7,120,920,40,15,864,180,32,7,980,200,64,7,6,7,102,153,153,126,126,153,153,102
DEFPROChisc:PROChead:PROCmup:PRINTTAB(0,3)FNlines:FORT%=0TO11:PRINTTAB(32,5+T%)CHR$156TAB(7,5+T%)CHR$129CHR$157CHR$135;:IFT%MOD11PRINThs$(T%)STRING$(20-LENhs$(T%)-LENSTR$hs%(T%),".");hs%(T%);"  "
NEXT:PRINT''FNlines:IFI%<>TRUE PROCgname
PRINTTAB(6,22)CHR$136"PRESS THE SPACE BAR TO PLAY":REPEATUNTILINKEY-99:ENDPROC
DEFPROChead:FORT%=0TO1:PRINTTAB(11,T%)CHR$141CHR$132CHR$157CHR$135"POLYMER PICKER  "CHR$156:NEXT:ENDPROC
DEFPROCmup:IFS%<=hs%(10):I%=TRUE:ENDPROC
I%=10:REPEAT:IFhs%(I%-1)<s%:hs%(I%)=hs%(I%-1):hs$(I%)=hs$(I%-1):I%=I%-1
UNTILI%=1ORhs%(I%+(I%<>FALSE))>=s%
hs%(I%)=s%:hs$(I%)=STRING$(10,"."):ENDPROC
DEFPROCgname:PRINTTAB(8,22)CHR$136"PLEASE ENTER YOUR NAME":T%=0:$&380=hs$(I%):PRINTTAB(9,5+I%)CHR$131;:*FX21
REPEAT:i%=GET:IFi%=13hs$(I%)=$&380:UNTILTRUE:PRINTTAB(9,5+I%)CHR$135:ENDPROC:ELSEIFi%<32ORi%>127UNTILFALSE
IFT%<14ANDi%<>127VDUi%:T%?&380=i%:T%=T%+1
IFT%>0ANDi%=127VDU8,46,8:T%=T%-1:IFT%<>10T%?&380=46
UNTILFALSE:ENDPROC
DEFFNlines:=CHR$146+STRING$(38,CHR$243)
DEFPROCr:*T.
*FX138,0,128
*FX3,2
IFPAGE>&E00:*KEY0FORT%=0TOTOP-PAGE STEP4:T%!&E00=T%!PAGE:N.|MPAGE=&E00|MOLD|MRUN|M