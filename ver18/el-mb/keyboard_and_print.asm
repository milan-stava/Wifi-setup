;wifi stahovatko, MB03
;keyboard and print routines
;HOod

;new feature: can hide passwords with "X"

;print type
;0=standart (print codes #D,#A as 
;1=omit codes #D,#A- take them as end of text (#D,#A= byte 0)
;2=codes #D,#A taken as a new line
print_type=1


;temporary
INPBUFF	ds 64		;63 editable bytes and a zero terminator
INLEN	db 0		;logical text length, independent of cursor
keysound db 0				;key sound 0= yes,1= no, klavesnicove echo
BORDER   db 1				;okraj


WTKY     xor  a				;ceka na stisk klavesy, nebo +b+ preruseni ;o)
         in   a,(254)		
         cpl  
         and  31
         ret  z
         ld   a,b
         or   a
         jr   z,WTKY
         ld   de,768
WTK2     ex   (sp),hl
         ex   (sp),hl
         dec  de
         ld   a,e
         or   d
         jr   nz,WTK2
         djnz WTKY
         ret  
         
WAIT     ei   				;cekaci smycka, musi se nastavit b-cko
WAIT2    halt 
         djnz WAIT2
         ret  



otherkey	defb $55
lastkey		defb $55
keywait		ld b,20
kw2		push bc
		ld b,0
kw1		djnz kw1
		pop bc
		djnz kw2
		ret
KEYSCAN
return_key			;first press, returns NZ, next presses Z, no return if no key pressed

keyboard	call inkey	;Busy's MRS solution- the best:))
		or a
		jr nz,keyb1
		ld (lastkey),a
		ret		;if no key pressed, RETurn with A=0 and Z flag
;		jr keyboard
/*alternativa, zpomaleni klavesnice pro rychlejsi CPU
keyb1		ei
		halt
		halt
		di
key_cont	ld c,a
*/	
keyb1		ld bc,$400


keyb2		dec c
		jr nz,keyb2
		djnz keyb2
		ld c,a
		call inkey
		cp c
		jr nz,keyboard
		ld a,(lastkey)
		cp c
		jr z,keyb3
		ld a,$80
		jr keyb4
keyb3		ld a,(otherkey)
		ld b,a
keyb7		xor a
keyb5		dec a
		jr nz,keyb5
		call inkey
		cp c
		jr nz,keyboard
		djnz keyb7
		ld a,1
keyb4		ld (otherkey),a
		ld a,c
		ld (lastkey),a
beep		push af
;		or a			;tento or je pro rutinu MRS dulezity, jinak rutina kvici
		call beepk		;beep
		pop af
		ret		;end of Busy's solution			

beepk		ld a,(keysound)		;Busyho nahradni rutina,kratsi
		or a
		ret nz
		ld a,(BORDER)
		xor	a		;black border
		ld e,a
		ld b,$10
		add a,b
;		ld a,$10+border
		out ($fe),a
		ld b,$1c
beepk1		djnz beepk1
		ld a,$08
		add a,e
;		ld a,$08+border
		out ($fe),a
		ret





;hl=umisteni (0-23,0-63)
AADRSET  ld   a,h			;vypocte adresu na obrazovce....
         push hl
         and  %00011000
         or   %01000000
         ld   l,0
         rr   h
         rr   l
         rr   h
         rr   l
         rr   h
         rr   l
         ld   h,a
         pop  bc
         bit  0,c
         jr   nz,AMODIFY
         ld   a,1
ACONT    srl  c
         ld   b,0
         add  hl,bc
         ret  
AMODIFY  xor  a
         jr   ACONT

POS2HL	ld	h,b
	ld	l,c
	ld	(HLKO+1),hl
HLKO	ld	hl,#4000		;init, zacatek screenu
	ret


PRINT   ld hl,(HLKO+1) 
PRINTHL	bit 4,(ix+0)
	ret z			;we do not want to print anything
	push hl			;vypise text. Konec textu je definovan bytem 0
         call ADRSET
         pop  bc
         ex   de,hl
         jr   z,SECND
FIRST    ld   a,(hl)
         or   a
	jr	z,POS2HL

	IFN print_type=0	;start of conditional assembly
	cp	#D

	IF print_type=2
	jr	z,f2
	ENDIF

	IF print_type=1
	jr	z,POS2HL	;codes #D, and #A interpretted as end of text
	ENDIF


	cp	#A
	
	IF print_type=2
	jr	nz,f1
	ENDIF

	IF print_type=1
	jr	z,POS2HL
	ENDIF

	IF print_type=2
f2	ld	a,#10		;omit codes #D, #A
	add	a,e		;
	and	%11110000	;
	ld	e,a		;skip to next line
	inc	hl		;
	jr	FIRST		;
	ENDIF
	ENDIF			;end of conditional assembly
	
f1        cp 1
         jr nz,f1_char
         ld a,44
f1_char  push hl
         push de
         push bc
         add  a,a
         ld   l,a
         ld   h,0
         add  hl,hl
         add  hl,hl
         ld   bc,FONT-256
         add  hl,bc
         ex   de,hl

;ver27 vracime zpet font na #B700, takze i zrychlujeme rutinu;ver26, kvuli posunu fontu kvuli volnemu mistu davame o 2 takty pomalejsi instukci, ale font muzeme umistit mimo nasobky #10 (bylo tam jen inc e)..... musi tu byt INC DE a font muze byt kdekoliv

	DUP 7
	ld	a,(hl)
	and	%00001111
	ld	b,a
        ld   a,(de)
        and  %11110000
	or	b
         ld   (hl),a
         inc  de
         inc  h			
	EDUP

	ld	a,(hl)
	and	%00001111
	ld	b,a
        ld   a,(de)
        and  %11110000
	or	b
         ld   (hl),a


/*
         ld   a,(de)		
         and  %11110000
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %11110000
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %11110000
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %11110000
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %11110000
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %11110000
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %11110000
         or   (hl)
         ld   (hl),a
*/

         pop  bc
         inc  c
         pop  de
         pop  hl
         inc  hl
SECND    ld   a,(hl)
         or   a
	jp	z,POS2HL

	IFN print_type=0	;here starts conditional assembly
	cp	#D

	IF print_type=2
	jr	z,s2
	ENDIF

	IF print_type=1
	jp	z,POS2HL	;codes #D, and #A interpretted as end of text
	ENDIF


	cp	#A

	IF print_type=2
	jr	nz,s1
	ENDIF

	IF print_type=1
	jp	z,POS2HL
	ENDIF

	IF print_type=2
s2	ld	a,#10		;
	add	a,e		;omit codes #D, #A
	and	%11110000	;
	ld	e,a		;skip to next line
	inc	hl		;
	jr	SECND		;
	ENDIF
	ENDIF			;end of conditional assembly


s1       cp 1
         jr nz,s1_char
         ld a,44
s1_char  push hl
         push de
         push bc
         add  a,a
         ld   l,a
         ld   h,0
         add  hl,hl
         add  hl,hl
         ld   bc,FONT-256
         add  hl,bc
         ex   de,hl


	DUP 7
	ld	a,(hl)
	and	%11110000
	ld	b,a
        ld   a,(de)
        and  %00001111
	or	b
         ld   (hl),a
         inc  de
         inc  h			
	EDUP

	ld	a,(hl)
	and	%11110000
	ld	b,a
        ld   a,(de)
        and  %00001111
	or	b
         ld   (hl),a



/*
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         ld   a,(de)
         and  %00001111
         or   (hl)
         ld   (hl),a
*/


         pop  bc
         inc  c
         pop  de
         pop  hl
         inc  de
	jr nz,cth
	ld a,#40
	cp d			;chces na 9 radek? Pak skoc na nulty
	jr nc,cth
	ld d,a
;         call z,CTH		;prozatini reseni, tisk v kuse jen do horni jen tretiny
cth         inc  hl
         jp   FIRST
         
;CTH      ld   a,d
;         add  a,8
;         ld   d,a
;        ret  

;start bc=4002, de=4000
;prvni 4,BC=4000, de=407F
;druha ctyrka. BC=4000, de=4100

         
         
ADRSET   ld   a,h			;vypocte adresu na obrazovce...
         push hl
         and  %00011000
         or   %01000000
         ld   l,0
         rr   h
         rr   l
         rr   h
         rr   l
         rr   h
         rr   l
         ld   h,a
         pop  bc
         bit  0,c
         ld   a,1
         jr   z,CONT
         xor  a
CONT     srl  c
         ld   b,0
         add  hl,bc
         or   a
         ret  
TIMEOUT  db "Time out"
         db $00,$C9



;hl=umisteni
;a=kod znaku
CHAR     ld   b,a			;vypis znaku 
         and  %11100000
         ld   a,b
         jr   nz,CHAR0
         ld   a,32
CHAR0    
         push bc
         push de
         push hl
         push af
         call AADRSET
         or   a
         jr   z,ASECND2
         ld   c,$F0
         jr   ASECND1
ASECND2  ld   c,$0F
ASECND1  pop  af
         ex   de,hl
         ld   l,a
         ld   h,0
         add  hl,hl
         add  hl,hl
         add  hl,hl
         push bc
         ld   bc,FONT-256
         add  hl,bc
         pop  bc
         ex   de,hl


         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         inc  de
         inc  h
         
         ld   b,(hl)
         ld   a,c
         cpl  
         and  b
         ld   (hl),a
         ld   a,(de)
         and  c
         or   (hl)
         ld   (hl),a
         
         pop  hl
         pop  de
         pop  bc
         inc  l
         ret  




;rutina INPUT v MBC vklada znaky z klavesnice
;OUT C=pozice kurzoru. 0= nic vlozeno
INPUT    ld   hl,INPBUFF
         ld   b,63
IN1      ld   (hl),32
         inc  hl
         djnz IN1
         
;         ld   hl,12*256+15	;zbytecne, odstranil jsem v ftp klientovi 0.97
;        ld   a,32
;         call CHAR
         
         xor  a
         ld   (hl),a		;terminate editable buffer
;         ld   (hl),a		;ver27, pryc, prepisuje to pamet a neni to asi potreba
INPUT2   ld   (INLEN),a
         ld   (CURSOR+1),a
;         ld   hl,12*256+16	;puvodni z MBC
         ld   hl,txt_adr_edit_zone2
         ld   (INPOS+1),hl
IN2      ld   b,63
INPOS    ld   hl,0
         ld   de,INPBUFF
CURSOR   ld   c,0
;IN3      ld   a,e

IN3
		push	hl
		push	de
		ld	h,d
		ld	l,e
		ld	de,INPBUFF
		or	a
		sbc	hl,de
		ld	a,l
		pop	de
		pop	hl


         push bc
         cp   c
         jr   nz,INXXX
         ld   a,c
         or   a
         ld   b,'>'
         jr   z,CURTV2
         ld   b,'_'
CURTV2   ld   a,b
         push de
         call CHAR
         pop  de
INXXX   ld   a,(de)
	bit	7,a
	res	7,a
	jr	z,INXXX3		;Z=normal ASCII, NZ=tisk "X"
	ld	a,"X"			;pokud je nastaven 7.bit, tiskni X misto znaku
INXXX3	         push de
         call CHAR			;samotny tisk znaku
         pop  de
		inc	de
;         inc  e
         pop  bc
         djnz IN3

		push	hl
		push	de
		ld	h,d
		ld	l,e
		ld	de,INPBUFF
		or	a
		sbc	hl,de
		ld	a,l
		pop	de
		pop	hl
		

;         ld   a,e
         cp   c
         jr   nz,INXXX2
         ld   a,c
         cp   ixh
         ld   b,'<'
         jr   z,CURTV
         ld   b,'_'
CURTV    ld   a,b
         call CHAR
INXXX2   ld   b,1	;puvodne bylo 15 a kurzor byl liny a spatne reagoval
         call WTKY
INQQQ    call KEYSCAN
	or a
         jr   z,INQQQ	;tady se vyhodnoti klavesnice a tisknutelne znaky se daji do bufferu, ktery se vytiskne, viz vyse
;         jr   nz,INQQQ
;         ld   a,e
;         inc  a
;         jr   z,INQQQ
;         ld   a,d
;         ld   hl,iiss
;         cp   $18
;         jr   z,INSSS
;         ld   hl,iics
;         cp   $27
;         jr   z,INSSS
;         ld   hl,iinn
;INSSS    ld   d,0
;         add  hl,de
;         ld   a,(hl)
;         or   a
;         jr   z,INQQQ
         cp   4
;         ret  z
		jp	z,IN_END 
        cp   13
		jp	z,IN_END
;         ret  z
         cp   199
         jp   z,INPUT
         ld   hl,IN2
         push hl
         ld   hl,CURSOR+1
         cp   8
         jr   z,CURSLEFT
         cp   9
         jr   z,CURSRGHT
         cp   12
         jr   z,BCKSPACE
         cp   15
         jr   z,DELETE
         cp   32
         ret  c
         cp   128
         ret  nc

;INX_HS		set	7,a		;hlavni rutina to tu modifikuje set 7,a= bude se tisknout "X"
INX_HS	db	#CB			;bajty #CB+nop= instrukce RLC B... bude tisknout ASCII
	nop


IN6         ex   af,af'
         ld   a,(hl)
         cp   ixh
         ret  nc
         inc  (hl)
         push hl
         ld   a,(INLEN)
         cp   ixh
         jr   nc,IN_LEN_KEEP
         inc  a
         ld   b,a
         ld   a,(hl)
         cp   b
         jr   nc,IN_LEN_SET
         ld   a,b
IN_LEN_SET ld (INLEN),a
IN_LEN_KEEP pop hl
         ld   l,(hl)
         dec  l

		push	de
		ld	a,l
		ld	hl,INPBUFF
		ld	de,0
		ld	e,a
		add	hl,de
		pop	de
		


;         ld   h,INPBUFF/256

IN5      ld   a,(hl)
         or   a
         ret  z
         ex   af,af'
         ld   (hl),a
         inc  hl
         jr   IN5
CURSLEFT ld   a,(hl)
         or   a
         ret  z
         dec  (hl)
         ret  
CURSRGHT ld   a,(hl)
         cp   ixh
         ret  nc
         inc  (hl)
         ret  
DELETE   ld   a,(hl)
         cp   ixh
         ret  nc
         inc  a
         jr   BCK2
BCKSPACE ld   a,(hl)
         or   a
         ret  z
         dec  (hl)
BCK2     ld   l,a
         ld   a,(INLEN)
         cp   l
         jr   c,IN_DEL_KEEP
         dec  a
         ld   (INLEN),a
IN_DEL_KEEP

		push	de
		ld	a,l
		ld	hl,INPBUFF
		ld	de,0
		ld	e,a
		add	hl,de
		pop	de


;         ld   h,INPBUFF/256

         ld   e,l
         ld   d,h
	dec	de		;byl error, pri deletu to mohlo mazat pamet
;         dec  e
DEL2     ld   a,(hl)
         ldi  
         or   a
         jr   nz,DEL2
         ex   de,hl
	dec	hl
;         dec  l
         ld   (hl),' '
         ret  

IN_END		ld	b,63			;na konci musime smazat vsechny 7 bity
		ld	hl,INPBUFF
IN_END1		res	7,(hl)
		inc	hl
		djnz	IN_END1
		ld	hl,CURSOR+1
		ld	c,(hl)			;C=pozice kurzoru
		ret
	

	include "inkey.a80"	;ver26, premistujeme na #BF01



DOWNHL   inc  h				;voala, tohla snad musi byt vsude :))))
         ld   a,h
         and  7
         ret  nz
         ld   a,l
         add  a,32
         ld   l,a
         ret  c
         ld   a,h
         sub  8
         ld   h,a
         ret  



FONT
TOFONT	
	incbin "1_W1250.BIN"      



