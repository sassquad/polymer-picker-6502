N%=RND(-TIME):PROCi:S%=0:REPEAT:MODE7:VDU23;8202;0;0;0;:HIMEM=&2BFF:PROCh:S%=0:l%=1:MODE2:VDU23;8202;0;0;0;:HIMEM=&2BFF:REPEAT:PROCo:PROCA:PROCa:PROCb:PROCn:IFl%>8PROCf:PROCs:ELSEIF(l%MOD2)=1:PROCf:ELSE:PROCs
PROCg:PROCB:PROCe:PROCC:TIME=0:REPEAT:PROCv:PROCD:IFl%>8PROCm:PROCE:ELSEIF(l%MOD2)=1:PROCm:ELSE:PROCE
PROCl:UNTILP%=0ORL%=0ORO%<928:IFP%=0ANDO%>927PROCF:l%=l%+1
UNTILL%=0ORO%<928:PROCG:UNTIL0
DEFPROCi:k%=&AB8:n%=&AC0:q%=&AC8:t%=&AD0:F%=&AD8:G%=&AE0:J%=&AE8:DIMh%(8),h$(8):RESTORE97:FORT%=1TO8:h%(T%)=(9-T%)*500:READh$(T%):NEXT:h%(1)=75000:ENDPROC
DEFPROCo:VDU4,12:FORZ=0TO15:VDU19,Z,0;0;:NEXT:M$="GET READY!":IFl%>4M$="OH BOY...!":IFl%>8M$="AAAAAAAGH!"
VDU19,14,7;0;17,14,31,5,15:PRINT;M$:PROCt:ENDPROC
DEFPROCn:VDU4,17,128,31,5,15:PRINTSPC(10):FORZ=0TO15:VDU19,Z,Z;0;:NEXT:VDU19,0,4;0;19,15,0;0;19,14,6;0;5:READo%,p%:VDU19,8,o%;0;19,9,p%;0;:ENDPROC
DEFPROCA:RESTORE(93+(l%MOD4)):READv:VDU28,0,4,19,0,17,v,12,26:READci%,m%:IFci%=1READw,x,y,z:PROCc(w,x,y,z)
IFci%=2:FORa=1TO2:READw,x,y,z:PROCc(w,x,y,z):NEXT
IFm%=1READw,x,y,z:PROCH(w,x,y,z)
IFm%>1FORa=1TOm%:READw,x,y,z:PROCH(w,x,y,z):NEXT
VDU4,28,0,31,19,27,17,143,12,26,28,0,28,19,27,17,132,12,26,5:FORT=242TO247:VDU23,T:FORI=1TO8:VDURND(255):NEXT,:FORy=127TO160STEP32:FORx=0TO1279STEP64:VDU18,0,3,25,4,x;y;RND(6)+241:NEXT,:FORG=0TO9:h=RND(2)+224:VDU18,0,15,25,4,(G*136)+8;224;h,10,8,224,18,0,2,25,4,G*136;224;h,10,8,224:NEXT
FORG=3TO6:VDU18,0,5,25,4,64+(G*136);192;227:NEXT:ENDPROC
DEFPROCa:D%=32:e%=214:f%=1:PROCd(f%,D%,e%):P%=8:L%=8:O%=1224:M%=300:V%=1:g%=1:H%=0:K%=0:IF(l%MOD2)=1cr%=228:co%=1:ELSEcr%=229:co%=5
cx%=FNg:VDU5,18,3,co%,25,4,cx%;192;cr%:ENDPROC
DEFPROCb:VDU18,0,15,25,4,512;920;230,231,232,10,8,8,8,233,234,235,236,18,0,7,25,4,512;924;230,231,232,10,8,8,8,233,234,235,236:ENDPROC
DEFPROCf:FORA=0TO7:k%?A=FNr(1):n%?A=FNy:q%?A=3:F%?A=3:IFA>3q%?A=1:F%?A=2
t%?A=8:PROCd(F%?A,k%?A,n%?A):NEXT:E%=0:ENDPROC
DEFPROCs:SD%=4:SX%=FNr(4):SY%=60+(l%*10):IFSY%>140SY%=140
IFSX%<=(D%+12)SD%=5
PROCd(SD%,SX%,SY%):ENDPROC
DEFPROCm:IFq%?E%=2ANDn%?E%=0:E%=(E%+1)MOD8:ENDPROC
PROCd(F%?E%,k%?E%,n%?E%):k%?E%=k%?E%+q%?E%-2:n%?E%=n%?E%+t%?E%-6:IFk%?E%<4q%?E%=3:F%?E%=3
IFk%?E%>75q%?E%=1:F%?E%=2
IFn%?E%<64ANDq%?E%<>2t%?E%=8ELSEIFn%?E%<48ANDq%?E%=2n%?E%=48
IFn%?E%>200ANDq%?E%<>2t%?E%=4
PROCd(F%?E%,k%?E%,n%?E%):IFq%?E%<>0PROCk((k%?E%+3*(F%?E%-2))*2,n%?E%-5,E%)
IFq%?E%<>0:IFl%>4:IFFNb(k%?E%,n%?E%)PROCu
E%=(E%+1)MOD8:ENDPROC
DEFPROCE:OS%=SX%:OY%=SY%:OA%=SD%:IF(SX%+8)<(D%+6)ANDSX%<62:SX%=SX%+V%:SD%=5
IF(SX%+6)>(D%+6)ANDSX%>1:SX%=SX%-V%:SD%=4
IFSY%<e%ANDSY%<194SY%=SY%+V%
IFSY%>e%ANDSY%>64SY%=SY%-V%
PROCd(OA%,OS%,OY%):PROCd(SD%,SX%,SY%):IFFNb(SX%+8,SY%)PROCu
ENDPROC
DEFPROCg:READa,b,c,d,e,f,g,h:VDU23,251,a,b,c,d,e,f,g,h:FORA=0TO7:G%?A=(A+1)*16:J%?A=((RND(153)-1)+48):VDU18,3,7,25,4,G%?A*8;J%?A*4;251:NEXT:ENDPROC
DEFPROCB:VDU26,4,17,143,17,7,31,1,30,251,32,17,7:PRINT;P%:VDU31,11,30:PRINT"Air":IF(l%MOD2)=1ORl%>8:VDU31,6,30,17,6,241,32,17,7:PRINT;L%
VDU17,128,5:ENDPROC
DEFPROCe:VDU4,17,7,31,6,0:PRINT"$"STRING$(6-LENSTR$S%,"0");S%;:VDU5:ENDPROC
DEFPROCC:VDU5,18,0,14:MOVE920,40:MOVE1216,40:PLOT85,920,52:PLOT85,1216,52:ENDPROC
DEFPROCD:IFTIME<M%ENDPROC
O%=O%-(8*g%):SOUND0,4,6,3:IFO%>912VDU18,0,15,25,4,O%;52;25,5,O%;40;25,4,O%+8;52;25,5,O%+8;40;
IFO%>999VDU19,14,6;0;ELSEVDU19,14,9;0;
IFO%<1068:IFH%=0ANDK%=0SOUND2,3,240,2:VDU18,3,6,25,4,612;850;237;:K%=1
TIME=0:ENDPROC
DEFPROCv:A%=D%:B%=e%:C%=f%:IFINKEY(-(?&100+1))ANDD%>1:D%=D%-g%:f%=0
IFINKEY(-(?&101+1))ANDD%<67:D%=D%+g%:f%=1
IFINKEY(-(?&102+1))ANDe%<212:e%=e%+(g%*2)
IFINKEY(-(?&103+1))ANDe%>54:e%=e%-(g%*2)
IFINKEY(-(?&104+1))AND(D%<>A%ORe%<>B%):g%=2:M%=100:PROCD:ELSEg%=1:M%=200
PROCd(C%,A%,B%):PROCd(f%,D%,e%):U%=D%+6:Z%=e%-14:PROCI(U%*2,Z%):IFD%>30:IFD%<40:IFe%>210:IFO%<1068:IFH%=0:PROCJ
IFINKEY-56:REPEATUNTILINKEY-54
IFINKEY-17:*FX210,1
IFINKEY-82:*FX210,0
ENDPROC
DEFPROCI(X%,Y%):C%=FNc(X%,Y%):IFC%<8SOUND1,1,99,1:PROCK(C%)
PROCB:ENDPROC
DEFPROCK(c%):VDU18,3,7,25,4,G%?C%*8;J%?C%*4;251,4:P%=P%-1:S%=S%+200:G%?C%=255:J%?C%=255:PRINTTAB(13-LENSTR$S%,0);S%:ENDPROC
DEFFNb(i%,j%):IFi%<D%ORi%>(D%+12)ORj%<(e%-12)ORj%>e%:=FALSE:ELSE=TRUE
DEFPROCk(X%,Y%,E%):C%=FNc(X%,Y%):IFC%<8:PROCL(E%,C%)
ENDPROC
DEFPROCL(E%,C%):P%=P%-1:L%=L%-1:SOUND3,2,96,4:PROCd(F%?E%,k%?E%,n%?E%):F%?E%=F%?E%+4:PROCd(F%?E%,k%?E%,n%?E%):q%?E%=2:t%?E%=0:PROCB:VDU18,3,7,25,4,G%?C%*8;J%?C%*4;251:G%?C%=255:J%?C%=255:ENDPROC
DEFPROCl:oc%=cx%:cx%=cx%+6:IFcx%>1260cx%=0
IFcx%<>oc%VDU5,18,3,co%,25,4,oc%;192;cr%,25,4,cx%;192;cr%
ENDPROC
DEFPROCJ:O%=1224:SOUND1,1,80,1:PROCC:H%=1:K%=0:V%=1:VDU18,3,6,25,4,612;850;237;:ENDPROC
DEFPROCu:M%=150:PROCD:V%=2:SOUND2,2,148,4:VDU18,3,1:FORz=1TO4:PLOT69,(D%*16)+RND(64),(e%*4)+RND(64):NEXT:ENDPROC
DEFPROCF:IF(l%MOD2)=1ORl%>8PROCM
PROCp:PROCw:ENDPROC
DEFPROCM:B=0:FORA=0TO7:IFq%?A<>2ANDn%?A<>0SOUND2,1,(30+B*10),1:S%=S%+50:B=B+1:PROCe:VDU18,0,1,25,4,k%?A*16;(n%?A*4)+40;238
FORz=1TO400:NEXT,:ENDPROC
DEFPROCp:SOUND3,0,0,1:FORz=0TO999:NEXT:REPEAT:SOUND&11,-10,O%/8,2:VDU18,0,15,25,4,O%;52;25,5,O%;40;:O%=O%-8:S%=S%+50:PROCe:UNTILO%<920:O%=1224:ENDPROC
DEFPROCG:SOUND3,2,96,4:PROCw:VDU4,17,co%,12,31,5,15:PRINT"GAME  OVER":PROCw:ENDPROC
DEFPROCc(h%,v%,r%,c%):VDU24,0;864;1279;1023;29,h%;v%;18,0,c%:x%=r%:y%=0:z%=x%/2:REPEAT:VDU25,4,x%;y%;25,5,-x%;y%;25,4,y%;x%;25,5,-y%;x%;25,4,x%;-y%;25,5,-x%;-y%;25,4,y%;-x%;25,5,-y%;-x%;:y%=y%+1:z%=z%-y%:IFz%<0:z%=z%+x%:x%=x%-1
UNTILx%<y%:ENDPROC
DEFPROCH(mx%,w%,u%,b%):ox%=-32:oy%=0:L=w%/PI:VDU29,mx%;864;25,4,0;0;:FORx%=0TOw%STEP64:y%=40+RND(40)+u%*SIN(x%/L):VDU18,0,b%,25,4,x%;y%;25,4,x%;0;:PLOT85,ox%,oy%:PLOT85,ox%,0:VDU18,0,15,25,4,ox%;oy%+4;25,5,x%;y%+4;:ox%=x%:oy%=y%:NEXT
VDU25,5,x%+16;4;18,0,b%,25,4,ox%;0;25,4,ox%;oy%;:PLOT85,x%+16,0:ENDPROC
DEFPROCt:IFl%>8s%=92:ELSEIF(l%MOD2)=1:s%=90ELSEs%=91
RESTOREs%:d%=1:FORu=1TO7:READn:SOUNDd%,1,n,6:FORz=1TO400:NEXT:d%=d%+1:IFd%=4d%=1
NEXT:ENDPROC
DEFPROCw:TIME=0:REPEATUNTILTIME=300:ENDPROC
DEFPROCd(A%,X%,Y%):CALLW%:ENDPROC
DEFFNr(W):W=W*4:=(RND(73-W)-1)+4
DEFFNy:=(RND(153)-1)+48
DEFFNc(X%,Y%):CALLQ%:=?&AB2
DEFFNs(X%,Y%):CALLR%:=!&70AND&FFFF
DEFFNg:=(RND(32)+2)*32
DEFFNA:=(RND(33)+18)*16
DATA129,125,109,101,89,81,77
DATA77,81,89,101,109,125,129
DATA129,125,129,125,129,125,81
DATA131,1,2,40,860,40,5,864,120,32,1,980,200,64,1,6,7,66,66,126,126,126,126,126,126
DATA134,1,2,40,980,40,3,864,200,64,2,980,200,64,2,5,3,8,24,56,126,255,62,28,8
DATA133,1,2,40,860,40,1,864,180,32,15,980,200,64,15,5,3,120,-4,-1,-1,-1,-4,120,0
DATA143,2,2,100,920,40,7,120,920,40,15,864,180,32,7,980,200,64,7,6,7,102,153,153,126,126,153,153,102
DATASTEVE,NUNI,ANDON,EDORA,GRAEME,EWOK,ROCKY,ECCLES
DEFPROCh:PROCN:PROCO:FORT%=1TO8:VDU31,7,(3+T%*2),132,157,134:IFT%MOD9PRINTh$(T%)STRING$(20-LENh$(T%)-LENSTR$h%(T%),".");"$";h%(T%)
NEXT:IFI%<>TRUE:PROCP
VDU31,7,23,131,157,129:PRINT"Press SPACEBAR to play":REPEAT:VDU31,7,5,132,157,128+(RND(6)):FORz=1TO100:NEXT:UNTIL0 ORINKEY-99:ENDPROC
DEFPROCN:FORY=0TO24:VDU31,0,Y,131,157:NEXT:FORY=4TO21:VDU31,3,Y,132,157,31,36,Y,131,157:NEXT:FORY=1TO2:VDU31,0,Y,131,157,132,141:PRINTSPC7"Top Polymer Pickers":NEXT:ENDPROC
DEFPROCO:IFS%<=h%(8)I%=TRUE:ENDPROC
I%=8:REPEAT:IFh%(I%-1)<S%h%(I%)=h%(I%-1):h$(I%)=h$(I%-1):I%=I%-1
UNTILI%=1ORh%(I%+(I%<>FALSE))>=S%:h%(I%)=S%:h$(I%)=STRING$(14,"."):ENDPROC
DEFPROCP:VDU31,7,23,131,157,129:PRINT;"Please enter your name":T%=0:$&380=h$(I%):VDU31,9,3+I%*2,131:*FX21
REPEAT:i%=GET:IFi%=13h$(I%)=$&380:UNTILTRUE:VDU31,9,3+I%*2,135:ENDPROC:ELSEIFi%<32ORi%>127UNTILFALSE
IFT%<14ANDi%<>127VDUi%:T%?&380=i%:T%=T%+1
IFT%>0ANDi%=127VDU8,46,8:T%=T%-1:IFT%<>14T%?&380=46
UNTILFALSE:ENDPROC
