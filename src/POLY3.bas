REPEAT:VDU22,7:PRINTF$:PROCh:S%=0:l%=1:VDU22,2:PRINTF$:REPEAT:PROCo:PROCA:PROCa:PRINTC$;G$:READo%,p%:PRINTo%,p%:VDU19,8,o%;0;19,9,p%;0;:IFl%>8PROCf:PROCs:ELSEIFl%AND1:PROCf:ELSE:PROCs
PROCg:PROCB:PROCe:PROCC:TIME=0:REPEAT:PROCv:PROCD:IFl%>8PROCm:PROCE:ELSEIFl%AND1PROCm:ELSE:PROCE
PROCl:UNTILP%=0ORL%=0ORO%<928:IFP%=0ANDO%>927PROCF:l%=l%+1
UNTILL%=0ORO%<928:PROCG:UNTIL0
DEFPROCo:VDU4,12:FORZ=0TO15:VDU19,Z,0;0;:NEXT:M$="GET READY!":IFl%>4M$="OH BOY...!":IFl%>8M$="AAAAAAAGH!"
PRINTH$;M$:PROCt:ENDPROC
DEFPROCA:RESTORE(114+(l%MOD4)):READv:VDU28,0,4,19,0,17,v,12,26:READci%,m%:IFci%=1READw,x,y,z:PROCc(w,x,y,z)
IFci%=2:FORa=1TO2:READw,x,y,z:PROCc(w,x,y,z):NEXT
IFm%=1READw,x,y,z:PROCH(w,x,y,z)
IFm%>1FORa=1TOm%:READw,x,y,z:PROCH(w,x,y,z):NEXT
PRINTB$:FORT=242TO247:VDU23,T:FORI=1TO8:VDURND(255):NEXT,:FORy=127TO160STEP32:FORx=0TO1279STEP64:VDU18,0,3,25,4,x;y;RND(6)+241:NEXT,:FORG=0TO9:h=RND(2)+224:VDU18,0,15,25,4,(G*136)+8;224;h,10,8,224,18,0,2,25,4,G*136;224;h,10,8,224:NEXT:FORG=3TO6:VDU18,0,5,25,4,64+(G*136);192;227:NEXT:ENDPROC
DEFPROCa:D%=32:e%=214:f%=1:PROCd(f%,D%,e%):P%=8:L%=8:O%=1224:M%=300:V%=1:g%=1:H%=0:K%=0:ST%=0:IF(l%MOD2)=1cr%=228:co%=1:ELSEcr%=229:co%=5
cx%=(RND(32)+2)*32:VDU5,18,3,co%,25,4,cx%;192;cr%:ENDPROC
DEFPROCf:FORR%=0TO7:k%?R%=FNr(1):n%?R%=(RND(153)-1)+48:q%?R%=3:F%?R%=3:IFR%>3q%?R%=1:F%?R%=2
t%?R%=8:PROCd(F%?R%,k%?R%,n%?R%):NEXT:E%=0:ENDPROC
DEFPROCs:SD%=4:SX%=FNr(4):SY%=60+(l%*10):IFSX%<=(D%+8)SD%=5
IFSY%>140SY%=140
PROCd(SD%,SX%,SY%):ENDPROC
DEFPROCm:IFq%?E%=2IFn%?E%=0E%=(E%+1)AND7:ENDPROC
PROCd(F%?E%,k%?E%,n%?E%):k%?E%=k%?E%+q%?E%-2:n%?E%=n%?E%+t%?E%-6:IFk%?E%<4q%?E%=3:F%?E%=3
IFk%?E%>75q%?E%=1:F%?E%=2
IFn%?E%<64ANDq%?E%<>2t%?E%=8ELSEIFn%?E%<48ANDq%?E%=2n%?E%=48
IFn%?E%>200IFq%?E%<>2t%?E%=4
PROCd(F%?E%,k%?E%,n%?E%):IFq%?E%<>0PROCk((k%?E%+3*(F%?E%-2))*2,n%?E%-5,E%)
IFq%?E%<>0IFl%>4IFFNf(k%?E%,n%?E%)PROCu
E%=(E%+1)MOD8:ENDPROC
DEFPROCE:N%=SX%:j%=SY%:OA%=SD%:IFSY%<e%ANDSY%<194SY%=SY%+V%
IFSY%>e%ANDSY%>64SY%=SY%-V%
_%=4:IFSD%=5_%=8:IFSD%=8:_%=0
IF(SX%+_%)>(D%+6)SX%=SX%-V%:ELSEIF(SX%+_%)<(D%+6)SX%=SX%+V%
IFSX%>(D%+8)SD%=4
IFSX%<(D%-8)SD%=5:IFOA%=8SX%=SX%-8
IFSX%>(D%-8)ANDSX%<(D%+8)SD%=8:IFOA%=5SX%=SX%+8
IFSD%=8ANDFNs(SX%)PROCu
IFN%<>SX%ORj%<>SY%OROA%<>SD%PROCd(OA%,N%,j%):PROCd(SD%,SX%,SY%)
ENDPROC
DEFPROCg:READa,b,c,d,e,f,g,h:VDU23,251,a,b,c,d,e,f,g,h:FORA=0TO7:G%?A=(A+1)*16:J%?A=((RND(136)-1)+64):VDU18,3,7,25,4,G%?A*8;J%?A*4;251:NEXT:ENDPROC
DEFPROCB:PRINTD$;P%;:IF(l%MOD2)=1ORl%>8VDU31,6,30,17,6,241,32,17,7,(48+L%)
VDU17,128,5:ENDPROC
DEFPROCe:VDU4,17,7,31,7,0:PRINTSTRING$(6-LENSTR$S%,"0");S%;:VDU5:ENDPROC
DEFPROCC:PRINTA$:ENDPROC
DEFPROCD:IFTIME<M%ENDPROC
O%=O%-(8*g%):SOUND0,4,6,3:IFO%>912VDU18,0,15,25,4,O%;52;25,5,O%;40;25,4,O%+8;52;25,5,O%+8;40;
IFO%>999VDU19,14,6;0;ELSEVDU19,14,9;0;
IFO%<1068IFH%=0ANDK%=0SOUND2,3,240,2:VDU18,3,6,25,4,612;850;237;:K%=1
TIME=0:ENDPROC
DEFPROCv:A%=D%:B%=e%:C%=f%:IFINKEY(-(?&100+1))IFD%>1D%=D%-g%:f%=0
IFINKEY(-(?&101+1))IFD%<67D%=D%+g%:f%=1
IFINKEY(-(?&102+1))IFe%<212e%=e%+(g%*2)
IFINKEY(-(?&103+1))IFe%>54e%=e%-(g%*2)
IFINKEY(-(?&104+1))IF(D%<>A%ORe%<>B%):g%=2:M%=100:PROCD:ELSEg%=1:M%=200
IFA%<>D%ORB%<>e%ORC%<>f%PROCd(C%,A%,B%):PROCd(f%,D%,e%)
U%=D%+6:Z%=e%-14:PROCI(U%*2,Z%):IFD%>30IFD%<40IFe%>210IFO%<1068IFH%=0:PROCJ
IFINKEY-56:REPEATUNTILINKEY-54
IFINKEY-17:*FX210,1
IFINKEY-82:*FX210,0
ENDPROC
DEFPROCI(X%,Y%):C%=FNc:IFC%<8SOUND1,1,99,1:PROCK(C%)
PROCB:ENDPROC
DEFPROCK(c%):VDU18,3,7,25,4,G%?C%*8;J%?C%*4;251,4:P%=P%-1:S%=S%+200:G%?C%=255:J%?C%=255:PRINTTAB(13-LENSTR$S%,0);S%:ENDPROC
DEFPROCk(X%,Y%,E%):C%=FNc:IFC%<8PROCL(E%,C%)
ENDPROC
DEFPROCL(E%,C%):P%=P%-1:L%=L%-1:SOUND3,2,96,4:PROCd(F%?E%,k%?E%,n%?E%):F%?E%=F%?E%+4:PROCd(F%?E%,k%?E%,n%?E%):q%?E%=2:t%?E%=0:PROCB:VDU18,3,7,25,4,G%?C%*8;J%?C%*4;251:G%?C%=255:J%?C%=255:ENDPROC
DEFPROCl:oc%=cx%:cx%=cx%+6:IFcx%>1260cx%=0
IFcx%<>oc%VDU5,18,3,co%,25,4,oc%;192;cr%,25,4,cx%;192;cr%
ENDPROC
DEFPROCJ:O%=1224:SOUND1,1,80,1:PROCC:H%=1:K%=0:V%=1:PRINTE$:ENDPROC
DEFPROCu:M%=100:PROCD:SOUND2,2,148,4:VDU18,3,1,25,4,(D%*16)+RND(64);(e%*4)+RND(32);239;:ENDPROC
DEFPROCF:IF(l%MOD2)=1ORl%>8PROCM
PROCp:PROCw:ENDPROC
DEFPROCM:*FX21,6
B=0:FORA=0TO7:IFq%?A<>2ANDn%?A<>0SOUND2,1,(53+B*4),1:S%=S%+50:B=B+1:PROCe:VDU18,0,1,25,4,k%?A*16;(n%?A*4)+40;238
TIME=0:REPEATUNTILTIME=15:NEXT:ENDPROC
DEFPROCp:SOUND3,0,0,1:FORz=0TO999:NEXT:REPEAT:SOUND&11,-10,O%/8,2:VDU18,0,15,25,4,O%;52;25,5,O%;40;:O%=O%-8:S%=S%+50:PROCe:UNTILO%<920:O%=1224:ENDPROC
DEFPROCG:*FX21,6
SOUND3,2,96,4:PROCw:VDU4,17,co%,12,31,5,15:PRINT"GAME  OVER":PROCi:PROCw:ENDPROC
DEFPROCc(h%,v%,r%,c%):VDU24,0;864;1279;1023;29,h%;v%;18,0,c%:x%=r%:y%=0:z%=x%/2:REPEAT:VDU25,4,x%;y%;25,5,-x%;y%;25,4,y%;x%;25,5,-y%;x%;25,4,x%;-y%;25,5,-x%;-y%;25,4,y%;-x%;25,5,-y%;-x%;:y%=y%+1:z%=z%-y%:IFz%<0:z%=z%+x%:x%=x%-1
UNTILx%<y%:ENDPROC
DEFPROCH(mx%,w%,u%,b%):ox%=-32:oy%=0:L=w%/PI:VDU29,mx%;864;25,4,0;0;:FORx%=0TOw%STEP64:y%=40+RND(40)+u%*SIN(x%/L):VDU18,0,b%,25,4,x%;y%;25,4,x%;0;:PLOT85,ox%,oy%:PLOT85,ox%,0:VDU18,0,15,25,4,ox%;oy%+4;25,5,x%;y%+4;:ox%=x%:oy%=y%:NEXT
VDU25,5,x%+16;4;18,0,b%,25,4,ox%;0;25,4,ox%;oy%;:PLOT85,x%+16,0:ENDPROC
DEFPROCt:IFl%>8s%=112:ELSEIF(l%MOD2)=1:s%=110ELSEs%=111
RESTOREs%:d%=1:FORu=1TO7:READn:SOUNDd%,1,n,6:FORz=1TO400:NEXT:d%=d%+1:IFd%=4d%=1
NEXT:ENDPROC
DEFPROCi:RESTORE113:FORu=1TO8:READn,d:SOUND1,1,n,d:NEXT:ENDPROC
DEFPROCh:PROCN:PROCO:FORT%=1TO8:VDU31,7,(3+T%*2),132,157,134:IFT%MOD9PRINTh$(T%)STRING$(20-LENh$(T%)-LENSTR$h%(T%),".");h%(T%)
NEXT:IFI%<>TRUE:PROCP
VDU31,6,23,131,157,129:PRINT"Press SPACEBAR to play":REPEAT:VDU31,7,5,132,157,128+(RND(6)):FORz=1TO100:NEXT:UNTILINKEY-99:ENDPROC
DEFPROCN:FORY=0TO24:VDU31,0,Y,131,157:NEXT:FORY=4TO21:VDU31,3,Y,132,157,31,36,Y,131,157:NEXT:FORY=1TO2:VDU31,0,Y,131,157,132,141:PRINTSPC2"Polymer Pickers Hall of Fame":NEXT:ENDPROC
DEFPROCO:IFS%<=h%(8)I%=TRUE:ENDPROC
I%=8:REPEAT:IFh%(I%-1)<S%h%(I%)=h%(I%-1):h$(I%)=h$(I%-1):I%=I%-1
UNTILI%=1ORh%(I%+(I%<>FALSE))>=S%:h%(I%)=S%:h$(I%)=STRING$(14,"."):ENDPROC
DEFPROCP:VDU31,6,23,131,157,129:PRINT"Please enter your name":T%=0:$&380=h$(I%):VDU31,9,3+I%*2,131:*FX21
REPEAT:i%=GET:IFi%=13h$(I%)=$&380:UNTILTRUE:VDU31,9,3+I%*2,135:ENDPROC:ELSEIFi%<32ORi%>127UNTILFALSE
IFT%<14ANDi%<>127VDUi%:T%?&380=i%:T%=T%+1
IFT%>0ANDi%=127VDU8,46,8:T%=T%-1:IFT%<>14T%?&380=46
UNTILFALSE:ENDPROC
DEFPROCw:TIME=0:REPEATUNTILTIME=100:ENDPROC
DEFPROCd(A%,X%,Y%)CALLW%:ENDPROC
DEFFNf(c%,d%):IFc%<D%ORc%>(D%+12)ORd%<(e%-12)ORd%>e%:=FALSE:ELSE=TRUE
DEFFNs(a%):IF(D%-(a%+2))>0OR(D%-(a%+2))<13:IF(SY%+2)>=e%AND(SY%+2)<=(e%+16):=TRUE:ELSE:=FALSE
DEFFNr(W):W=W*4:=(RND(73-W)-1)+4
DEFFNc:CALLQ%:=?&AB2
110DATA129,125,109,101,89,81,77
DATA77,81,89,101,109,125,129
DATA129,125,129,125,129,125,81
DATA53,5,41,10,53,10,73,15,41,5,33,10,53,10,69,20
DATA131,3,1,40,860,40,5,864,120,32,1,980,200,64,1,6,7,66,66,126,126,126,126,126,126
DATA134,1,2,40,980,40,3,864,200,64,2,980,200,64,2,5,3,8,24,56,126,255,62,28,8
DATA133,1,2,40,860,40,1,864,180,32,15,980,200,64,15,5,3,120,-4,-1,-1,-1,-4,120,0
DATA143,2,2,100,920,40,7,120,920,40,15,864,180,32,7,980,200,64,7,6,7,102,153,153,126,126,153,153,102
