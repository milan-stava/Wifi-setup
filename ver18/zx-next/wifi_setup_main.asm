; WiFi Setup 1.8 ZX Next - native UART/CPU/RTC backend, 06.11.2026.
;Wifi_setup, for eLeMeNt ZX and MB03.
;Hood

;ver18
;just one version for both wifi modules (in mb/el)
;flash version for MB can be always debugged with nmi button and nmi menu
;keyboard input routine fixed (crashed at some circumstances)
;new: password can be hidden

/*
AT+RST- reset
-vrati hned OK, ale pak vraci chaos, protoze nejsou sladene rychlosti na zakladnich 115200B!!!
-vraci zakladni rychlost 115200B- takze po resetu nevraci hlaseni "ready"
-zachovava CWMODE

AT+RESTORE
-vrati hned OK, ale pak vraci chaos, protoze nejsou sladene rychlosti na zakladnich 115200B!!!
-vraci zakladni rychlost 115200B- takze po resetu nevraci hlaseni "ready"
-NEzachovava CWMODE

Tzn. pro me ucely se RESTORE chova stejne jako RST, akorat nezachovava CWMODE
Reseni:prikaz RESTORE i RST proved v zakladni rychlosti 115200B. U RESTORE porved navic i CWMODE1, to kvuli nazvu wifiny, kdy je nazve WIFI <null>modul nic nevraci. V modu CWMODE1 je vse ok.

*/

;eLeMeNt ZX version added (conditional assembly, see label: element)

/*
;conditional assembly: since 1.6 assembly of 3 versions happens in one go
machine		equ	0	;0=machine 0, 1=machine 1 (machine 1 enables debug it in nmi Devast
element		equ	1	;version for element, 0=no (then it will be MB03+), 1=yes
standalone	equ	1	;0=app for MB03 bios, 1= app runable as standalone
*/

;ver16
;TODO	DONE firmware 306 update info text
;TODO	DONE AT+RESTORE command added after update
;bugfix	DONE enter of "" string in AP name or AP password caused crash
;TODO	DONE when no APs- remove endless loop
;TODO	DONE some JPs replaced by calls
;TODO	DONE same error handler routine mechanism like in Sarah client
;added	DONE CWMODE display& change option

;ver1.5TODO:
;DONE	TODO display firmware version (AT+SDK)
;TODO upgrade firmware
;TODO set wifi name
;DONE	TODO display wifi name
;ver1.4a= wifi bios 1.9 added+ particular uart (MB or el)
;ver1.4= release 19.11.2022 (Schlimeisch 2022 edition:-), final release 13.1.2023
;bugfix: APs with long names caused error nr. 9 in AP list creation (19.11.2022)
;bugfix: default AP, your IP not displayed correctly right after wifi turn on
;bugfix: during ongoing TCP/UDP transmission (status 3), status and current AP shown badly
;new: IP address of ZX wifi module (4.12.2022)
;new: status and signal strength called every 0,5 sec (previously was all the time)
;new: terminal initial menu speed up


;todo for versions above 1.3:
;error messages should return with RET, not JP
;SM2.0 also could ret not only with IX+7 indication, but with a sign, if speed set successfuly or not.
;add display of error numbers 29, 30 to SM2.0
;solve garbage on Default AP, Auto AP, and default wifi speed, if speeds >16 selected
;terminal should always print menu fast, not scroll

;ver1.3= release version

;vy e eno: pokud je rychlost 13,14 a >16, pak aktualizovat prostredni 3 radky
;vy e eno: pri volbe  blbych rychlosti vycistit obrazovku dole, tzn cls edit_zone2 udelat
;vy e eno:switch speed konci na 1, ale ma koncit na nule
;vy e eno: problemy: pokud je rychlost <3, SM2.0 se na zacatku pri startu spatne pripojuje- vyreseno at_check hazel error, nastavil se mu timeout
;vy e eno:pri navratu z rychlosti <3 nahoru, se SM2.0 spatne pripojuje, vyreseno, viz nahore

;ver1.2= zcela nov  SM20
;ver1.1= ver10+SM20- integruji SM2.0 do verze 1.0.
;p u speed management 2.0

;ver0.91
/*
- predelavam speed management, je to stale 1.0, ale chci aby koncil uspesnym nastavenim rychlosti a reakci modulu na prikaz AT. Zbytek cteni AP a signalu uz bude zajistovat externi rutina "watch_status_and_signal_strength"
*/

;ver 0.9 continue after several months
/*todo (mnim ln  k vypu t n ):
- kosmetick   pravy... done 11:59 19.10.2021
- spolu s info o sile signalu neust le refre ovat i cipstatus (tzn. pokud tam sko   5, modul nen  p ipojen k AP)... done 23:07 18.10.2021
	- zjisti status-> tiskni ho-> nastav flag-> pokud nen  p ipojen, napi  to....done 23:08 18.10.2021
- volby:- "A- connect to AP" (user may select if default or current)... done 2:26 22.10.2021
	- "D- disconnect from AP"...done 3:58 16.10.2021
	- "R- reset module"....done 3:48 16.10.2021

todo dal   tipy (do dal  ch verz ):
- vypsat FW a napsat hl en , pokud FW nepodporuje max rychlost
- vypisov n  IP adres
- volby+ zprovozn n :
	- "set auto AP"
	- "set station name" - vypsat jm no modulu ( a m nit ho p  padn )
	- "select communication speed" (tzn. jak na uartu, tak na modulu)
*/

;- ver 0.8	- connect to AP:
;pripojovat se pomoci AT+CWJAP_CUR= docasne, POkud dam CWJAP nebo CWJAP_DEF, pak se dana sit stane defaultni
;- ver 0.7	- speed management improved: done (to be done: to set user_defined speed)
;		- print wifi system info
;- ver 0.6	- possible to assembly versions standalone or for MB03+ boot
;		- adding terminal by Tim Gilberts and co.
;		- error with year 1970 bugfixed (hopefully:)
;		- terminal returns with Wifi ON
;- ver 0.5	29.3.2021, release. Compiled from 0, ldired to #E400
;- ver 0.4.	28.3.2021, version purely in machine code, aimed for MB03+ setup
;- ver 0.3	addind Wifi reset (AT+RST command)
;tuto verzi d v me k ledu, je v n  rozprcov na nez vislost na BASICu (INPUT ze stroj ku)
;a tak  reset Wifi, jdeme d lat verzi 0.4 kter  bude jen stroj k, um st n  v setupu MB
;BASIC k 0.3. je v adres  i v TAP
;samostan  funguj c  utilita ve stroj ku. Z visl  ov em na posunu GMT, kter  se  te z MB03+
;- ver 0.2	adding CZ servers (GMT +1 by default) 
;		list of CZ SNTP servers: http://phoenix.inf.upol.cz/~bazgierv/ntp.html
;- ver 0.1	winter/summer time manually

/*since 1.6 assembly of all comes in one go
	IF element=0
	IF standalone=0
	output "wifi_setup_mb_flash"
	ELSE
	output "wifi_setup_mb_standalone"
	ENDIF
	ENDIF

	IF element=1
	IF standalone=0
	output "wifi_setup_el_flash"
	ELSE
	output "wifi_setup_el_standalone"
	ENDIF
	ENDIF
*/

;set C=		SCF
;set NC=	AND A, if Z needs to be preserved, then SCF:CCF

;overview:
;SENDING
;1) send_string:	mainly to send direct AT commands
;2) send_data:		to send any type of data


;RECEIVING
;7) receive_data_timeout receive data with timeout

;PARSING
;10) look_for_string:	seeks certain string in memory
;11) look_on_fly:	seeks certain string in the incoming flow of bytes


;OTHER
;16) ConvRStr16		converts ASCII to HL (16 bit)
;17) HL2ASCII		converts HL to ASCII (16 bit)
;18) wait routines	wait certain amount of time (user definable)
;29) send_at_check_ok	sends AT command and checks for answer OK

;40) set_print_speed	sets speed on MB UART and print it
;48) convASCII2hex	convert eg. "14" to #14
;49) cls_4000		clear screen
;50) cls_9		clear 9 lines
;51) prn_ap_name_sig	print AP name and signal strength
;52) get_status		gets status, if wifi is connected to Ap or not
;53) set_def_wifi_speed	sets both speeds to default wifi speed
;54) clear_edit_zone	clears 2 bottom lines
;55) akey		waits for key press
;56) wifi_wait/unwait	signals, that we wait for wifi
;57) set_ud_speed	sets user defined speed (0-23 from IX+2), mainly for SM2.0
;	DEFINE border_colour	;0=no colours,1=show border colours, yellow for disk operations,
				;violet= communication with module
	
buf_len		equ #8000	;nemelo by byt pevne, ale PHP script to ma tez pevne dano
;buf_len	equ #800
pause		equ 25		;number of interrupts
main_port	equ #203B
wifi_port	equ #213b
basic_end	equ #63E0
speed_pos	equ #4400
terminal_start	equ 30000
start_address	equ #C000	;ver 1.4
;start_address	equ #C800
AP_list_start	equ terminal_start+terminal_len	;start of AP list in the memory goes right after terminal
edit_zone1	equ #5600
edit_zone2	equ #5700
txt_adr_edit_zone2	equ #5700

;bios		equ	#FD00
bios		equ	bios_start
gver_inst	equ	bios+0
wifi_on		equ	bios+4
wifi_off	equ	bios+6
set_baud	equ	bios+8
bios_get_baud	equ	bios+10
clear_rece_buf	equ	bios+12
rece_byte	equ	bios+16
send_byte	equ	bios+18
rece_block	equ	bios+20
send_block	equ	bios+22


port_select	equ	#703B
element_port	equ	#783B


;Error reports
	;BC=1=send_string_error

	;BC=2=ntp server not responding within timeout
	;BC=3=CWMODE 1 not sucessull
	;BC=4=":" not found in raw time&date data
	;BC=7= correct time zone not activated

	;BC=5=AT_RST command not sent
	;BC=8=AT+CIPSNTPCFG command not accepted
	;BC=9=AP list not complete in the memory
	
	;BC=27=speed management: AT+UART command not sent- not used
	;BC=28=speed management: AT command not accepted
	;BC=29=speed management: all speeds tested, timeout, fix it in terminal-add it in the next ver
	;BC=30=speed management: failed, probably Wifi module wrongly set,fix in terminal-add it in the next ver
	;BC=31=user defined speed_ AT+UART_CUR command not sent
	;BC=32=user defined routine_ speed in UART not set
	;BC=33=user defined speed_ you try to set nonsence speed (ie. > 23)

;	IF standalone
	IFDEF standalone
		org start_address
	ELSE
		org	0
	ENDIF

start_ldir              di

;	IFN standalone
	IFNDEF standalone
		ld	bc,#1FFD	;page 48 ROM on +2A....nechce resetuje se do 128 ROM
		ld	a,4		;both pagings have to be placed still when PC is <16K
		out	(c),a

		ld	bc,#7FFD	;page 48 ROM on +2
		ld	a,#10
		out	(c),a


		ld	hl,strt_len
		ld	de,start_address
		ld	bc,total_len
		ldir

		ld	hl,terminal_code
		ld	de,terminal_start
		ld	bc,terminal_len
		ldir
		
		jp	start_address

strt_len	equ	$-start_ldir
	ENDIF


	IFNDEF standalone
;	IFN standalone
		disp	start_address
	ELSE
		disp	start_address+1
	ENDIF

/*
		ld	hl,bios_start		;useless code, ldirs itself
;		ld	de,0-bios_len
		ld	de,bios
		ld	bc,bios_len
		ldir
*/
;		call	0-bios_len
start_mb_flash
                        ld (restore_ix+2),ix
                        ld (restore_iy+2),iy
                        exx
                        ld (restore_alt_hl+1),hl
                        exx
                        call bios

		ld	ix,flag1

;	IF standalone
	IFDEF standalone
		ld	(stack_pointer+1),sp	;release version for MB03+
		ld	sp,0			;no need to save SP, RST 0 is at the end

		ld	hl,terminal_code
		ld	de,terminal_start
		ld	bc,terminal_len
		ldir
		xor	a
		out	(254),a
	ENDIF

;		ld	ix,flag1		;defined above already
		set	4,(ix+0)		;we want print at start

                        call next_init

;	IFN standalone
	IFNDEF standalone			;not standalone=flash, in that case we want to be able to debug setup
		ld	bc, port_select		;set machine 1= MB02+, 0= pure ZXS
;		push	bc
		xor	a
		out	(c),a
		inc	b

;;	IFDEF machine
;	IF machine
		inc	a			;inc a= machine 1= MB and BSDOS.
;	ENDIF
		out	(c),a

		ld	iy,#5C3A			

		ld	hl,systemky_code	;how to produce them? 1. boot pure BSROM
		ld	de,23552		;2.PRINT 1, 3. CLEAR terminal_start-1,
		ld	bc,systemky_len		;4. Save"" code 23552, 203
		ldir

	ENDIF
	
		and	a			;test if Wifi is on/off
		call	wifi_on
		set	3,(ix+0)
		jr	nz,st2			;Z=off, NZ=on
		res	3,(ix+0)
;		ld	(ix+2),#FF		;#FF=initial speed will be set to max,SM2.0


;flag1 (IX+0),bit 7=used in "HL2ASCII"
;bit 0=used in "look_for_string"
;bit 1=AT+RST comamnd,0=no, 1=yes	
;bit 2=input/zone shift=0=plus,1=minus
;bit 3=wifi on exit, 0=off,1=on
;bit 4=print info in speed management? 0=no, 1=yes
;bit 5=wifi connection status, 0= not connected to AP, 1= connected to AP
;bit 6=speed correctly set (module and UART), 0= no, 1= yes
;bit 7=AP list, 0=not complete, 1= complete
;(IX+1)= counter of AP in memory
;flag2 (IX+3).bit 0=print send command,0=NO, 1=YES
;bit 1=AP connection CURrent or DEFault (1=current, 0=default)
;bit 2= (related to bits 5,6) type of AP. 0=default, 1=current, (routine 51 only)
;bit 3=window for AP list or speed list? (1=AP list, 0= speed list)
;bit 4= default AP already read?, 0=no, 1=yes (routine 51 only)
;bit 5= your IP already read? 0=no, 1=yes (used in your_ip_call only)
;bit 6= current AP already read? 0=no, 1=yes (routine 51 only)
;bit 7= print_other info already called? 0=no, 1=yes
		
st2		ld	sp,basic_end
		ld	hl,error_handler_loop	;HL= address, where error handler jumps after an error occurs
		push	hl						

st1		call	cls_4000

		ld	de,title
		ld	hl,#4000+title_col
		call	PRINTHL
		ld	hl,#4100+title_col
		ld	b,title_len
underl		ld	a,34			;""""
		push	bc
		call	CHAR
		pop	bc
		djnz	underl		

		ld	de,ping_menu
		ld	hl,#5417
		call	PRINTHL
		ld	hl,#5420
		ld	de,set_speed_txt
		call	PRINTHL
		ld	hl,#542E
		ld	de,upgrade_firm
		call	PRINTHL

		ld	hl,#5216
		ld	de,press_psw_s_h
		call	PRINTHL
		ld	hl,#5224
		ld	de,press_set_rtc
		call	PRINTHL
		ld	hl,#5231
		ld	de,press_run_term
		call	PRINTHL
		ld	hl,#5311
		ld	de,press_reset		;=Q-quit
		call	PRINTHL
		ld	hl,#531A
		ld	de,change_mode
		call	PRINTHL
		ld	hl,#5323
		ld	de,new_name
		call	PRINTHL
		ld	hl,#5330
		ld	de,set_ap
		call	PRINTHL
		ld	hl,#5300
		ld	de,reset_wifi_txt
		call	PRINTHL
		ld	hl,#5400
		ld	de,disconn_AP_txt
		call	PRINTHL
		bit	0,(ix+3)
		ld	hl,#54E5	;"push hl:ld d,h"
		jr	nz,printyesno1
		ld	hl,#0518	;"jr ss2"
printyesno1	ld	(send_string),hl

		call	toggle_pass

kl1		set	4,(ix+0)		;print info in speed management
		call	speed_management

		res	7,(ix+3)		;set print_other_routine as not called yet

;		ld	hl,at_cwmode		;not needed, we want to preserve set CWMODE
;		call	send_string		;set module to station mode (CWMODE=1)
;		ld	hl,ok
;		call	look_on_fly
;		jr	z,kl2
;		ld	bc,3
;		jp	error

kl2		ld	hl,#4500
		ld	de,current_ap
		call	PRINTHL
		call	print_other_info	;auto AP, default speed



;		ei				;read it 50x sec (previous was all the time)
;		halt				;new in 1.4
;		halt
;		halt
;		nop
;		nop
;		nop
;		nop
;		di

error_handler_loop
		ld	sp,basic_end-2

key_loop	call	check_stat_sig

key_loop1	call	KEYSCAN
		cp	"i"
		jp	z,ping_host
		cp	"m"
		call	z,change_wifi_mode

;		jr	z,set_onoff
		cp	"s"
		call	z,set_rtc
;		jp	z,set_rtc
		cp	"a"
		set	3,(ix+3)
		call	z,set_user_defined_speed
;		jp	z,set_user_defined_speed
;		jp	z,set_acces_p
		cp	"q"
		jp	z,quit				;zustava jp, call byt nemuze
		cp	"t"
		call	z,run_terminal
		cp	"r"
		jp	z,reset_wifi
		cp	"p"
		call	z,set_passw_h_s
		cp	"d"
;		jp	z,disconnect_AP
		call	z,disconnect_AP
		cp	"v"
		res	3,(ix+3)
;		jp	z,set_user_defined_speed
		call	z,set_user_defined_speed
		cp	"f"
		jp	z,upgrade_fw
		cp	"n"
		call	z,set_new_name
;		jp	z,set_new_name
		jr	key_loop

check_stat_sig
		ld	b,pause			;25= every 0,5 sec, 50= every 1 sec, etc.
css1		call	inkey			;returns only if key pressed
		or	a
		ret	nz			;NZ=key pressed
		ei
		halt
		di
		djnz	css1
		call	watch_status_and_signal_strength	;read state of module every 0,5 sec, if key pressed, continue down...

		bit	7,(ix+3)		;print other info already called? Z=no, NZ=yes
		jr	nz,check_stat_sig
		bit	5,(ix+0)		;module connected to AP? Z=no, NZ=yes
;		jr	z,check_stat_sig
;		call	print_other_info	;default AP, auto AP, default speed, your IP
		call	nz,your_ip_call

		jr	check_stat_sig



run_terminal	
;	IF standalone
	IFDEF standalone
		ld	hl,#5C48		;BORDER colour
		ld	a,(hl)
		push	af
		ld	a,7
		ld	(hl),a
		push	hl
	ENDIF

;	IF standalone
	IFDEF standalone
		ld	hl,#1700		;set sys variables for terminal not to scroll at start
						;#1700 good value for standalone version
	ELSE
		ld	hl,#1821		;good value for flash version
	ENDIF
		ld	(23688),hl

		call	cls_4000
		call	set_def_wifi_speed	;sets speed 155200
		call	terminal_start
		di
                        ld a,#FF
                        ld (next_baud),a
;	IF standalone
	IFDEF standalone
		pop	hl
		pop	af
		ld	(hl),a
	ENDIF
		jp	st1

set_passw_h_s	ld	hl, flag3
		ld	a,(hl)
		xor	1
		ld	(hl),a

toggle_pass	bit	0,(ix+5)		;show password?
		ld	de,hide
		jr	z,tp1
		ld	de,show
tp1		ld	hl,#521D
		jp	PRINTHL



;speed management 2.0. starts here. Enables to set user_defined speed. Works with every MBFW.
;the principle:
;are you aligned?
;NO: try to align, if not success->error. If sucess, you have AKT (=current alligned speed is ;known). Is user defined speed definied? (IX+2=255 for no user defined speed) yes, END. NO. set ;speed according to ix+2 (max up to MBFW), end
;
;YES:
;is user defined speed set? (ix+2=255 or other?) NO=check if FW is 7/12? YES, align at speed
;ix+2, end. FW is higher then 7/12, then check if AKT=IX+2? YES, end, NO, align at ix+2, END.
;ix+2 was not 255, is FW 7/12? YES, then set FWmax, end. NO the is AKT=MBFW max? YES, then END
;NO, then align at FW max speed, end
;output: ix+7= 0-23 if speed set, or 255 if not set

;SM20 uses:
;bit 4,(ix+0)	PRINT or not to PRINT
;(ix+8)		contains maximum speed by detected MBFW (7, 12 or 23)
;(ix+6)		timeout value
;bit 6,(ix+0)	state of speed alignment between uart& module, 0 not aligned
;bit 5,(ix+0)	state of module connection to AP, 0 not connected to AP

;internal subroutines: switch_speed, print_bauds, find_out_speed
;external subroutines: send_at:check_ok, set_ud_speed, set_print_speed, print_speed

speed_management
		ld	(ix+7),#FF		;reset currently set speed status
		res	6,(ix+0)		;set signal UART and module speed not aligned

		ld	hl,#4300
		ld	de,wifi_on_off
		call	PRINTHL

		scf				;power on wifi
		call	wifi_on


		ld	hl,speed_pos		;print "Speed" text
		ld	de,speed
		call	PRINTHL

		push	ix
		call	gver_inst
		pop	ix			;A= max MBFW speed= 7 or 12 or 23
		ld	(ix+8),a		;save max possible speed for given FW

		ld	(ix+6),1		;timeout for quick AT check, 1 should be ok.
		call	send_at_check_ok
		jr	z,speed_aligned		;Z= speed aligned (UART<-> module)

						;speed not aligned
		call	switch_speed		;try to find out aligned speed
		jr	z,align_success
;		pop	hl
		ld	c,29
;		ld	bc,29			;solve in next versions
;		jr	nz,speed_uart_err

speed_uart_err	call	print_bauds		;print speed in bauds even if speed no communicate

		ld	hl,edit_zone1
		ld	de,module_no_aswer
		call	PRINTHL
;		ld	bc,30
	
speed_m_error	res	5,(ix+0)		;set signal wifi not connected to AP
;		jp	error	
sme1		call	akey
		call	undraw_cursor		;return from AP selection
		call	wind_cls
		call	clear_edit_zone
		ret
;zde konci vetev, kdy na pocatku SM2.0 nebylo nalezeno slazeni rychlosti

;zde jsme ze zacatku rychlost nasli a zkoumame, zda je to ta, kterou chceme, pokud ne, tak ji nastav
speed_aligned	call	find_out_speed		;output: D= currently aligned speed
align_success	call	set_ud_speed

;ve speed_we_want vyhodnotit, zda je odezva na AT prikaz. Pokud ne, neznamen  to,  e
;rychlosti nebyly slazeny, ale ze nektere z rychlosti 0-23 nekomunikuji s modulem.
speed_we_want	ld	(ix+6),#A
		call	send_at_check_ok
		jr	nz,speed_uart_err

wifi_cont					;we are at speed we want. Final steps... print UART speed+ Baud speed
		set	6,(ix+0)		;signal, that uart and module speed is aligned

;		call	get_baud
		call	find_out_speed
		ld	a,d			;A=aligned speed we ended with
		ld	(ix+7),a		;save it
		call	print_speed
		call	print_bauds

		ld	hl,ate0
		call	send_string
		ld	hl,ok
		jp	look_on_fly
;		call	look_on_fly
		;test for answer should be here?
;		ret		

;SM2.0 subroutines
find_out_speed          call get_baud
                        jr nc,fos1
                        call switch_speed
                        ld a,d
fos1                    ld d,a
                        ret


						;tests speeds <7-0>, then <max-8>
;switch_speed	ld	a,7			;start with speeds 7-0 (quicker finds the speed)
;		call	sws2
;		ret	z			;Z= speed <0,7> found

switch_speed	ld	a,(ix+8)		;try out every speed if you find connection UART+Wifi
						;start with max speed, end with 0
sws2		push	af
		call	set_print_speed

		call	clear_rece_buf		;very important to clear receive buffer!!!

		pop	af			;we need to inrease timeout for speeds <3
		push	af
		cp	3
		ld	(ix+6),1		;set timeout for 1 for speeds >3
		jr	nc,sws1
		ld	(ix+6),#A		;set tieout for #A for speeds <2

sws1		call	send_at_check_ok
		pop	de
		ret	z			;Z=answer found, D= speed set in HW
		ld	a,d
		dec	a
		cp	255			;test for 255, so that also speed 0 is tested
		jr	nz,sws2
		dec	a			;NZ=not successfull
		ret


print_bauds	call	get_baud		;print speed in Bauds...solved in bios 1.8
		push	de			;E=number of zeros. If MBFW=7 or 12, zeros speed in Bd is printed
		ld	de,block_asci
		ld	a,"="
		ld	(de),a
		push	de			;DE=start of speed to print
		inc	de
		ld	a,32
		ld	(de),a
		inc	de
		ld	h,b
		ld	l,c
		call	HL2ASCII
		pop	hl			;HL=start of speed to print
		pop	bc			;C=number of zeros
		ld	b,c
		ld	a,"0"
prbloop		ld	(de),a
		inc	de
		djnz	prbloop
		xor	a
		ld	(de),a
		ld	d,h
		ld	e,l
		ld	hl,#4400+9+8
		call	PRINTHL
		ld	de,Bd
		call	PRINT

		ld	de,mbfw			;print max UART speed supported by found MB FW
		call	PRINT
		ld	l,(ix+8)
		ld	h,0
		ld	de,block_asci
		push	de
		call	HL2ASCII
		ld	a,h
		ld	(de),a
		pop	de
		call	PRINT
		ld	de,spaces+27
		jp	PRINT
;end of speed management 2.0 here




; One ping, with the existing editor, encoder and bounded response waiter.
ping_host
		call	clear_edit_zone
		ld	de,ping_prompt
		ld	hl,edit_zone1
		call	PRINTHL
		push	ix
		ld	ixh,63
		call	INPUT
		pop	ix
		cp	4
		jr	z,ping_cancel
		ld	a,(INLEN)
		or	a
		jr	z,ping_cancel
		ld	hl,ping_at
		ld	de,TX_buf
		ld	bc,9
		ldir
		ld	hl,INPBUFF
		ld	a,(INLEN)
		ld	c,a
		call	at_escape
		jr	c,ping_failed
		ex	de,hl
		ld	(hl),34
		inc	hl
		ld	(hl),13
		inc	hl
		ld	(hl),10
		inc	hl
		ld	(hl),b
		call	clear_rece_buf
		call	wifi_wait
		ld	hl,TX_buf
		call	send_string
		jr	nz,ping_failed
		ld	hl,ping_plus
		call	ap_wait_line
		jr	nz,ping_failed
		ld	hl,RX_buf
		ld	de,INPBUFF
		ld	bc,16
		ldir
		xor	a
		ld	(INPBUFF+15),a
		ld	hl,ok_
		call	ap_wait_line
		jr	nz,ping_failed
		ld	de,INPBUFF
		jr	ping_show
ping_failed
		ld	de,ping_error
ping_show
		call	wifi_unwait
		call	uf3	;clear, show result, wait for key, clear again
		jp	key_loop
ping_cancel
		call	clear_edit_zone
		jp	key_loop

; Special '+' result pattern: accept a whole unsigned decimal reply only.
ping_reply
		ld	a,(de)
		cp	43
		ret	nz
		inc	de
		ld	a,(de)
		cp	48
		ret	c
ping_digit
		cp	58
		jr	nc,ping_bad_reply
		inc	de
		ld	a,(de)
		or	a
		ret	z
		cp	48
		jr	nc,ping_digit
ping_bad_reply
		or	1
		ret
ping_at		db 'AT+PING="'
ping_plus	db "+",0
ping_error	db "Ping failed",0
ping_menu	db "I- Ping",0
ping_prompt	db "Ping IP/host: ",0
set_new_name	ld	de,station_name+8
		ld	hl,edit_zone1
		call	PRINTHL

		push	ix
		ld	ixh,32		;input 32 byte string
		call	INPUT		;SS+Q initialise INPUT process
		pop	ix		;TRUE VIDEO= abort

		cp	4
		jr	nz,snn1		;Z=INPUT abort

		jp	klAP_ret+6

snn1		ld	de,TX_buf	;prepare command+ new name to the buffer
		push	de
		ld	hl,at_cwhostname
		ld	bc,13
		ldir
		ex	de,hl
		ld	(hl),"="
		inc	hl
		ld	(hl),34		;uvozovky
		inc	hl
		ex	de,hl

		ld	hl,INPBUFF
		ld	a,(INLEN)
		ld	c,a
		ld	b,0
		call	at_escape
		pop	hl	;TX_buf (builder can fail without unbalancing the stack)
		jp	c,at_input_error
		push	hl

		ex	de,hl
		ld	(hl),34
		inc	hl
		ld	(hl),#D
		inc	hl
		ld	(hl),#A
		inc	hl
		ld	(hl),c

		pop	hl
		call	ap_send_ok
		call	nz,uf5		;print error if not OK
		call	clear_edit_zone
		ld	hl,#4900
		ld	b,8*1
		call	cls_9_lines
		jp	poi3
;		jp	print_other_info
;		jp	read_cwhostname
;		jp	key_loop

		

watch_status_and_signal_strength
		call	get_status		;display status if AP connected, or not

		ld	de,#450C		;input DE= print position
		jp	prn_ap_name_sig		;read signal strength

;		bit	5,(ix+0)		;Z=AP not connected
;		ex	af,af'
;		call	z,your_ip_call		;read your IP
;		ex	af,af'
;
;		ret	nz			;
;
;		ld	hl,at_cwjap_def?	;read default AP
;		ld	de,#470C
;		jp	prn_ap_name_sig_def


		


reset_wifi	ld	hl,edit_zone1
		ld	de,wifi_reset
		call	PRINTHL

		ld	hl,at_rst
		push	hl			;AT command

		call	set_def_wifi_speed	;switch to default wifi speed (now 115200)

		ld	(ix+6),1		
resw1		call	send_at_check_ok
		ld	c,28
		jp	nz,error_handler

resw5		pop	hl			;AT command either AT+RST or AT+RESTORE
		call	send_string

;		ld	hl,AP_list_start
;		ld	de,30000
;		ld	b,h
;		ld	c,l
;		call	receive_data1

		ld	hl,ready
		push	hl
		call	look_on_fly
		pop	de
		ld	c,5
;		ld	bc,5
		jp	nz,error_handler

		ld	hl,edit_zone2
		call	PRINTHL
		call	clear_rece_buf

;		jp	kl1
		jp	cwjap_ret2


;disconnects from AP
disconnect_AP	ld	hl,at_cwqap
		call	ap_send_ok
dap1
		ld	c,1
		jp	nz,error_handler
;		jr	resw2
;		jp	kl1
		ret

;no other way, than to wait for CIUPDATE:4, then OK
upgrade_fw	bit	5,(ix+0)
		jp	z,uf2
;		ret	z		;Z=not connected to AP, napsat hlaseni

;		set	0,(ix+4)	;indicate we go AT+RESTORE

		ld	de,update_warn
		ld	hl,edit_zone1
		call	PRINTHL
		ld	de,control_keys+34
		call	PRINT
uf55		call	KEYSCAN
		or	a
		jr	z,uf55
		cp	7
		jp	z,klAP_ret
;		jr	uf55
;		call	uf3
		
		ld	hl,e1-4
		ld	(uf_pointer+1),hl

		call	clear_edit_zone
		ld	hl,edit_zone1
		ld	de,update_in_prog
		call	PRINTHL

		call	set_def_wifi_speed

		ld	(ix+6),1		
uf56		call	send_at_check_ok
		ld	c,28
		jp	nz,error_handler

		ld	hl,at_ciupdate
		call	send_string
		jp	nz,uf5

		call	wifi_wait

		ld	b,4

uf4		push	bc
uf_pointer	ld	hl,e1-4
		ld	bc,4
		add	hl,bc
		ld	(uf_pointer+1),hl
		call	ap_wait_line	;E:1..E:4 suffix, accepts CIUPDATE/CIPUPDATE
		pop	bc
		jr	nz,uf5
		djnz	uf4
uf6		ld	hl,ok_
		call	ap_wait_line
		jr	nz,uf5
		call	wifi_unwait
		ld	de,connect_success+15
		call	uf3			;PRINT
		ld	hl,at_restore
		push	hl
		jp	resw5			;hand over to original AT+RST routine

;		call	speed_management	;with update, speed is lost, find speed again

;		ld	hl,at_cwmode		;tady to byt nemuze, to je blbost
;		call	send_string
;		ld	hl,ok
;		call	look_on_fly
/*
		ld	hl,at_restore		;restore module after update
		call	ap_send_ok
		ld	hl,ready
		push	hl
		call	look_on_fly
		pop	de
		ld	c,5
;		ld	bc,5
		jp	nz,error_handler
		push	de
		ld	hl,at_cwmode		;tady to byt nemuze, to je blbost
		call	ap_send_ok
		pop	de
		jp	resw4
*/
;		call	send_string
;
;uf7		and	a
;		call	rece_byte
;		jp	z,cwjap_ret2	;navrat do hlavni smycky
;		call	clear_rece_buf
;		jr	uf7
;uf8		jp	resw3		;wait for ready.....


;		ld	hl,ok
;		call	look_on_fly
;		jp	kl1		;start speed management

uf5		ld	de,error_txt
		call	uf9
		jp	kl1

;;		jr	uf3
uf2		ld	de,no_ap
uf3		push	de
		call	clear_edit_zone
		pop	de
uf9		ld	hl,edit_zone1
		call	PRINTHL
		call	akey
		call	clear_edit_zone
		ret

set_user_defined_speed
;spole n  pro AP list i set_user_defined_speed
		bit	3,(ix+3)		;we set speed or select AP?
;		ex	af,af'			;1=AP list, 0=speed list
		push	af
		call	set_acces_p		;prepare variables

;		ex	af,af'
		ld	de,speed_table

		pop	af
;;		push	af			;ulo  flag pro speed nebo AP

		jr	nz,spol1		;NZ=we set AP
;		jr	z,spol1			;Z=we set speed

		ld	a,(ix+8)
		inc	a
		ld	(ix+1),a		;max lines in window for speed according to MBFW
		jr	spol2

;		ex	af,af'
spol1		call	sap4			;read AP list to memory
		ld	de,AP_list_start

		;ex	af,af'
spol2		ld	(AP_item),de
		call	wind_new		;display either AP list, or list of speeds


		ld	hl,(cursor_w_stadr)	;starting position of window
		ld	(cursor_w_curad),hl	;and make it current add
		call	draw_cursor

;		pop	af
;		ex	af,af'			;vyvolej
;		push	af			;uloz
;		jr	nz,prep_ed_zone

		
prep_ed_zone	;ex	af,af'
		call	klAP1
;;		pop	af			;vyvolej flag, jde o speed nebo AP?
;;		ex	af,af'			;uloz ho

key_loop_AP_sp	call	check_stat_sig
		call	KEYSCAN
		ld	d,(ix+10)		;pointer to AP list, starts with 1
		ld	e,(ix+1)		;E=number of APs in memory
;		ex	af,af'			;uloz klavesu
;		ld	b,a			;klavesa do B
		cp	#B			;up
		jr	z,item_up
		cp	#A			;down
		jr	z,item_down
		cp	7			;edit key= escape
		jp	z,klAP_ret

;		ex	af,af'			;vyvolej

		bit	3,(ix+3)		;AP or speed?
		jr	z,speed_keys
		ld	hl,flag2

;		ex	af,af'			;uloz
;		ld	a,b			;klavesa

		cp	#D
		res	1,(hl)
		jp	z,enter_password
		cp	3			;SS+Enter= user want to set the AP as current
		set	1,(hl)
		jp	z,enter_password

;key_loop1	call	watch_status_and_signal_strength
		jr	key_loop_AP_sp

speed_keys;	ex	af,af'			;uloz
		cp	#D
		jr	z,select_speed
		jr	key_loop_AP_sp
;		jr	key_loop1



item_up		call	undraw_cursor
		ld	a,d
		cp	1
		jr	z,wind_end_start	;upper end of AP list
		dec	a
		ld	(ix+10),a
		call	item_nr
		ld	(AP_item),de		;DE points to desired item
		dec	c			;Z= already first position of cursor in window
		jr	nz,it_up1
		ld	hl,wind_curs_item
		dec	(hl)
		ld	a,(hl)
		call	item_nr		
		call	wind_new
		jr	wind_end_start
it_up1		ld	(ix+15),c
		ld	hl,(cursor_w_curad)
		ld	de,32
		or	a
		sbc	hl,de
		ld	(cursor_w_curad),hl
		jr	wind_end_start


item_down	call	undraw_cursor
		ld	a,d
		sub	e
		jr	z,wind_end_start	;end of AP list
		inc	d
		ld	(ix+10),d
		ld	a,d
		call	item_nr
		ld	(AP_item),de		;DE points to desired item
		ld	a,b
		sub	c			;Z= already last position of cursor in window
		jr	z,it_dw1
		inc	(ix+15)
		ld	hl,(cursor_w_curad)
		ld	de,32
		add	hl,de
		ld	(cursor_w_curad),hl
		jr	wind_end_start
it_dw1		ld	hl,wind_curs_item
		inc	(hl)
		ld	a,(hl)
		call	item_nr
		call	wind_new


wind_end_start	call	draw_cursor
		jp	key_loop_AP_sp


select_speed	ld	de,(AP_item)		; selected Next BIOS index 0..14
		call	ConvRStr16
		; Every entry in the Next speed table is valid.

sel_spd_go	ld	(ix+2),l		;L= speed we want (0-23=bios convention)
		call	sme1+3			;clear screen without waiting for a key
		jp	kl1
;		call	speed_management	;set the newly selected speed
;		jp	klAP_ret		;user defined speed should be sucessfully set

sel_spd_ask	ex	af,af'
		ld	hl,edit_zone2
		ld	de,sel_spd_ask_txt
		call	PRINTHL
		ld	de,yesno
		call	PRINT
sels1		call	KEYSCAN
		cp	"n"
		jp	z,klAP_ret
		cp	"y"
		jr	nz,sels1
		ex	af,af'
		ld	l,a
		jr	sel_spd_go


;connects to user selected AP
set_acces_p	xor	a
		ld	(ix+1),a		;reset AP counter
		inc	a
		ld	(ix+10),a		;set AP list pointer to 1
		ld	(ix+21),a		;window pointer
		ld	(ix+15),a		;current line is 1(ix+15), max line is IX+16
		ret

sap4		ld	a,"1"
		ld	(at_cwmode+10),a
		ld	hl,at_cwmode		;set CWMODE to 1
		call	ap_send_ok
sap5
		ld	c,3
		jp	nz,error_handler

		call	read_cwmode

		ld	hl,at_cwlapopt
		call	ap_send_ok		;APs will be sorted according to RSSI
sap2
		ld	c,9
		jp	nz,error_handler

		call	wifi_wait
		ld	hl,at_cwlap
		call	send_string
		ld	hl,AP_list_start
		ld	bc,#C000-AP_list_start
		ld	(ix+6),#80
sap3
		ld	de,#2000	;allow scan response fragments to arrive
		call	receive_data1
		ld	(ap_scan_end),hl
		push	hl
		push	bc
		ld	de,AP_list_start
		or	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	hl,AP_list_start
		ld	de,ok
		call	look_for_string
		pop	bc
		pop	hl
		jr	z,sap1
		ld	a,b
		or	c
		jp	z,ap_list_err
		dec	(ix+6)
		jr	nz,sap3
		jp	ap_list_err
sap1
		call	wifi_unwait
		ld	hl,(ap_scan_end)
		ld	de,AP_list_start
		or	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		ld	hl,AP_list_start
ap_list_loop
		push	de
		ld	de,ap_cwlap
		call	look_for_string
		jr	nz,ap_list_done
		ex	de,hl
		pop	de
		call	at_quoted
		jp	c,ap_list_err
		call	at_char
		jp	c,ap_list_err
		cp	44
		jp	nz,ap_list_err
		ld	a,1
		ld	(de),a
		inc	de
ap_rssi_copy
		call	at_char
		jp	c,ap_list_err
		cp	41
		jr	z,ap_rssi_end
		ld	(de),a
		inc	de
		jr	ap_rssi_copy
ap_rssi_end
		xor	a
		ld	(de),a
		inc	de
		inc	(ix+1)
		jp	z,ap_list_err
		jr	ap_list_loop
ap_list_done
		pop	de
		xor	a
		ld	(de),a
		ld	a,(ix+1)
		or	a
		jp	z,klAP_ret
		ld	hl,read_cw_ret
		push	hl
		ld	(hl),#C3
		call	read_cwhostname
		pop	hl
		ld	(hl),#CD
		ret


;		ld	hl,#4000+(32*7)
;		ld	b,6*8
;		call	cls_9_lines

;		ld	de,AP_list_start
;		ld	(AP_item),de
;		call	wind_new




klAP1		call	clear_edit_zone		;clear edit zone and print user info text
		ld	de,control_keys
		bit	3,(ix+3)
		jr	nz,klap2		;NZ=AP list
		ld	de,contr_k_speed
klap2		ld	hl,edit_zone1
		call	PRINTHL
		ret






;(ix+1)= total number of APs found. Pointer=ix+10, starts with 1
;item selection from APs list
;input a=item number (starts with 1)
item_nr		ld	hl,AP_list_start	;find an AP item in memory
;		ex	af,af'
;		or	a
		bit	3,(ix+3)
		jr	nz,inr1
		ld	hl,speed_table
inr1;		ex	af,af'
		dec	a
		jr	z,anl2
		ld	b,a
ap_num_loop	ld	a,(hl)
		or	a			;we seek for byte 0
		inc	hl
		jr	z,anl1
		jr	ap_num_loop
anl1		djnz	ap_num_loop
anl2		ex	de,hl			;DE points to desired item
		ld	bc,(cursor_cur_pos)
		ret





undraw_cursor	ld	a,7
		jr	dc_1
draw_cursor	ld	a,56
dc_1		ld	hl,(cursor_w_curad)
		ld	b,#20
dc_2		ld	(hl),a
		inc	hl
		djnz	dc_2
		ld	a,(ix+15)
		ret
		
wind_new	push	de			;input DE= start of AP list
;		ld	(AP_item),de
		call	wind_cls
		pop	de
		ld	hl,(wind_adr)
		ld	a,(ix+16)		;A=items a page
pal1		push	hl
		push	af
		push	de
		call	PRINTHL
		pop	de
		pop	af
		pop	hl
		dec	a
		ret	z
;		jr	z,ap_prn_pag_end
		inc	h
		ld	b,a
pr_ap_loop	ld	a,(de)
		or	a
		inc	de
		jr	nz,pr_ap_loop
		ld	a,(de)
		or	a
		ret	z
;		jr	z,ap_prn_pag_end
		ld	a,b
		jr	pal1





wind_cls	ld	hl,#4860		;clears window with AP list
		ld	a,(ix+16)
		add	a,a
		add	a,a
		add	a,a
		ld	b,a
		jp	cls_9_lines



;test if already connected, if not, connect to AP
enter_password
		ld	hl,at_cwjap_cur?
		call	send_string
		jr	nz,ep_not_connect
		ld	hl,RX_buf
		ld	bc,128
		call	receive_data_timeout
		ld	hl,RX_buf
		ld	de,RX_buf
		ld	bc,128
		call	at_quoted
		jr	c,ep_not_connect
		call	clear_edit_zone
		ld	hl,edit_zone1
		ld	de,already_connect
		call	PRINTHL
		ld	de,RX_buf
		call	PRINT
		ld	hl,edit_zone2
		ld	de,do_you_want_rec
		call	PRINTHL
		ld	hl,(AP_item)
		push	hl
ep7		call	ap_separator
		jp	c,at_input_error
		ld	(hl),0
		pop	de
		push	hl
		call	PRINT
		pop	hl
		ld	(hl),1
		ld	de,yesno
		call	PRINT

ep4		call	KEYSCAN
		cp	"n"
		jp	z,go_klAP1
		cp	"y"
		jr	nz,ep4


ep_not_connect	call	clear_rece_buf	;user wishes to connect
		call	clear_edit_zone
		ld	de,ent_psw	;enter password for selected AP
		ld	hl,edit_zone1	;AP name+password should be checked for:,\: !!!!!!!!
		call	PRINTHL		;then different syntax should be sent
		ld	hl,(AP_item)
		push	hl
enc1		call	ap_separator
		jp	c,at_input_error
		ld	(hl),0
		pop	de
		push	hl		;seznam zpet do puvodniho stavu?
		call	PRINT


		xor	a		;chceme schovat heslo?
		bit	0,(ix+5)
		jr	nz,set_pass1
		dec	a
set_pass1	ld	(INX_HS+1),a

		push	ix
		ld	ixh,63		;63 editable bytes plus zero terminator
		call	INPUT		;SS+Q initialise INPUT process
		pop	ix		;TRUE VIDEO= abort

		cp	4
		pop	hl
		ld	(hl),1
		jr	nz,ep11		;ENTER accepts an empty password too

ep13		ld	(hl),44	;restore AP list on abort
		xor	a
		ld	(INX_HS+1),a	;restore visible input for other callers
		jp	go_klAP1	;TRUE VIDEO cancels input

ep11		xor	a		;dej NOP do rutiny INPUT
		ld	(INX_HS+1),a	;chceme zase vypsat ASCII, ne "XXXX.."
		ld	hl,at_cwjap_join	;seznam zpet do puvodniho stavu?
		ld	de,TX_buf
		ld	bc,14
		ldir

		;CUR is the template; DEF is sent only after success.


ep12		ld	hl,(AP_item)
		push	hl
		call	ap_separator
		pop	hl
		jp	c,at_input_error
		call	at_escape
		jp	c,at_input_error
		ex	de,hl

		ld	(hl),#22
		inc	hl
		ld	(hl),44
		inc	hl
		ld	(hl),#22
		inc	hl
		ex	de,hl

		ld	hl,INPBUFF
		ld	a,(INLEN)
		ld	c,a
		ld	b,0
		call	at_escape
		jp	c,at_input_error

ep102		ex	de,hl
		ld	(hl),#22
		inc	hl
		ld	(hl),#D
		inc	hl
		ld	(hl),#A
		inc	hl
		ld	(hl),b
		call	wifi_wait
		ld	hl,TX_buf
		call	ap_send_ok
		jp	nz,ap_join_failed
		bit	1,(ix+3)
		jr	nz,ap_join_success	;current-only selection must not change DEF
		ld	hl,#4544	;DE
		ld	(TX_buf+9),hl
		ld	a,"F"
		ld	(TX_buf+11),a
		ld	hl,TX_buf
		call	ap_send_ok	;credentials have already passed the CUR join
		jp	nz,ap_join_failed
ap_join_success
		call	wifi_unwait
		ld	hl,edit_zone2
		ld	de,connect_success
		call	PRINTHL
ap_join_finish	call	undraw_cursor
		call	wind_cls
ap_join_prompt          call akey
                        call clear_edit_zone
                        jp kl2           ; AP result does not require baud re-detection
cwjap_ret2	call	akey
		call	clear_edit_zone
		jp	kl1

; A failed trial never changes the saved default credentials.
; Keep the original reason visible while restoring the saved default.
ap_join_failed
		call	wifi_unwait
		call	clear_edit_zone
ap_reason_value	ld	a,"4"
		ld	de,cwjap_err_1
		cp	"1"
		jr	z,ap_reason_print
		ld	de,cwjap_err_2
		cp	"2"
		jr	z,ap_reason_print
		ld	de,cwjap_err_3
		cp	"3"
		jr	z,ap_reason_print
		ld	de,cwjap_err_4
ap_reason_print
		ld	hl,edit_zone1
		call	PRINTHL
		ld	de,default_ap
		ld	hl,edit_zone2
		call	PRINTHL
		call	ap_restore_default
		call	wifi_unwait	;LD/JR only: preserves the result flags
		ld	de,off
		jr	nz,ap_restore_message
		ld	de,on
ap_restore_message
		ld	hl,edit_zone2+12
		call	PRINTHL
		jp	ap_join_finish

ap_restore_default
		;sap4 already saved CWMODE=1 before displaying the AP list.
		ld	hl,at_autocon
		call	ap_send_ok
		ret	nz
		ld	a,(ap_value)
		cp	"2"
		jp	nc,ap_restore_bad
		ld	(ap_autocon_state),a
                        ld a,(ix+7)
                        ld (ap_restore_speed+1),a
                        ld d,a
		call	set_def_wifi_speed
		ld	a,(ap_autocon_state)
		cp	"0"
		jr	nz,ap_restore_restart
		inc	a	;original Auto AP was ASCII 0
		ld	(ap_autocon_arg),a
		ld	hl,ap_autocon_set
		call	ap_send_ok
		jr	nz,ap_restore_cleanup_bad
ap_restore_restart
                        res 1,(ix+4)     ; boot-ready event belongs to this restart
		call	clear_rece_buf
		ld	hl,at_rst
		call	send_string
		jr	nz,ap_restore_cleanup_bad
		;No command is needed between reboot and GOT IP; ignore ready.
		ld	hl,ap_got_ip
                        ld bc,500       ; bounded fallback, <=10s at 50Hz (bytes also count)
                call ap_wait_budget
                push af                  ; preserve AP result across UART restoration
                jr z,ap_restore_uart     ; GOT IP also proves that boot progressed
                bit 1,(ix+4)
                jr z,ap_restore_uart_done ; never transmit at an unready ESP
ap_restore_uart
ap_restore_speed ld a,#FF                 ; original aligned baud, not speed 7
                ld d,7                   ; restart baseline is 115200
                call set_ud_speed_a      ; one known change, no search/AT probing
                ld (ix+7),a
ap_restore_uart_done
                pop af
                jr ap_restore_cleanup
ap_restore_cleanup_bad
		or	1
ap_restore_cleanup
		push	af
ap_auto_value	ld	a,"1"
		cp	"0"
		jr	nz,ap_restore_cleanup_done
		ld	(ap_autocon_arg),a
		ld	hl,ap_autocon_set
		call	ap_send_ok
		jr	z,ap_restore_cleanup_done
		pop	af
ap_restore_bad
		or	1
		ret
ap_restore_cleanup_done
		pop	af
		ret

; Whole-line results; at most 3000 bytes/idle frames, no RX overflow.
ap_send_ok
		ld	a,"4"	;generic failure unless the module supplies a reason
		ld	(ap_value),a
		push	hl
		call	clear_rece_buf
		pop	hl
		call	send_string
		ret	nz
		ld	hl,ok_
ap_wait_line
		ld	bc,3000       ; normal AP joins/commands retain their original budget
ap_wait_budget
		ld	(ap_expected),hl
		ld	de,RX_buf
ap_wait_poll
		dec	bc
		ld	a,b
		or	c
		jr	z,ap_restore_bad
		scf
		call	rece_byte
		jr	nz,ap_wait_byte
		ei
		halt
		di
		jr	ap_wait_poll
ap_wait_byte
		cp	13
		jr	z,ap_wait_poll
		cp	10
		jr	z,ap_wait_complete
		ld	(de),a
		ld	a,e
		cp	LOW (RX_buf+126)
		jr	z,ap_wait_poll
		inc	de
		jr	ap_wait_poll
ap_wait_complete
		ld	(ap_reply_end),de
		xor	a
		ld	(de),a
		ld	a,(RX_buf)
		cp	"+"
		jr	nz,ap_wait_event
		dec	de
		ld	a,(de)
		cp	"0"
		jr	c,ap_wait_event
		cp	"5"
		jr	nc,ap_wait_event
		ld	(ap_value),a
ap_wait_event
		push	bc

                ld hl,ready
                call ap_line_equal
                jr nz,ap_wait_result
                set 1,(ix+4)
ap_wait_result
ap_target	ld	hl,ok_
		call	ap_line_equal
		jr	z,ap_wait_found
		ld	a,(RX_buf)
		cp	"F"	;FAIL
		jr	z,ap_wait_failed
		cp	"E"	;ERROR
		jr	z,ap_wait_failed
		pop	bc
		ld	de,RX_buf
		jr	ap_wait_poll
ap_wait_found
		pop	bc
		ret
ap_wait_failed
		pop	bc
		jp	ap_restore_bad
ap_line_equal
		ld	de,RX_buf
		ld	a,(hl)
		cp	43
		jp	z,ping_reply
		cp	69	;OTA progress patterns E:n match a bounded line suffix
		jr	nz,ap_line_equal_next
		push	hl
		ld	hl,(ap_reply_end)
		ld	de,RX_buf+3
		or	a
		sbc	hl,de
		pop	hl
		ld	de,RX_buf
		jr	c,ap_line_equal_next
		ld	de,(ap_reply_end)
		dec	de
		dec	de
		dec	de
ap_line_equal_next
		ld	a,(de)
		cp	(hl)
		ret	nz
		inc	de
		inc	hl
		or	a
		jr	nz,ap_line_equal_next
		ret

ap_reply_end	dw 0
ap_expected	equ ap_target+1
ap_value	equ ap_reason_value+1
ap_autocon_state equ ap_auto_value+1
ap_autocon_set db "AT+CWAUTOCONN="
ap_autocon_arg db "1",13,10,0
ap_got_ip	db "WIFI GOT IP",0

go_klAP1	call	klAP1			;
		jp	key_loop_AP_sp


no_more_APs
;ap_prn_pag_end
;		jp	key_loop

ap_list_err	ld	c,9
		;ld	bc,9
		jp	error_handler

;prints:
;default AP
;auto AP:
;default speed
;cwhostname
;FW version
;CWMODE
print_other_info
;		bit	6,(ix+0)
;		ret	z
		ld	hl,#4000+(32*7)
		ld	b,8*3
		call	cls_9_lines

poi3		ld	de,default_ap		;read &print default AP
		ld	hl,#4600
		call	PRINTHL
		
;		ld	hl,at_cwjap_def?	;moved to your_ip
;		ld	de,#470C
;		call	prn_ap_name_sig_def	;print 



		ld	de,auto_ap		;read &print AP auto connection status
		ld	hl,#4800
		call	PRINTHL

		ld	hl,at_autocon
		call	send_string

		ld	bc,100
		ld	hl,RX_buf
		push	hl
;		ld	de,#800
;		call	receive_data1
		call	receive_data_timeout
		pop	hl
		ld	de,dvojt
		call	look_for_string
		jr	nz,poi2

		ld	a,(de)			;C=0 for not autocon, 1= yes, autocon
		ld	de,off
		cp	"0"
		jr	z,poi1
		ld	de,on
poi1		call	PRINT



poi2		ld	de,def_wifi_speed	;read &print default wifi speed
		ld	hl,#4900
		call	PRINTHL

;		call	clear_rece_buf

		ld	hl,at_uart_def
		call	send_string

		ld	bc,100
		ld	hl,RX_buf
		push	hl
		ld	de,#800			;speed 0- did not help
		call	receive_query
;		call	receive_data_timeout
		pop	hl

		ld	de,dvojt
		call	look_for_string
		ret	nz			;not found
		inc	hl			;HL=start of the string to print	
		push	hl
		ld	de,carka
		call	find_required
		ld	(hl),0
		pop	de
		ld	hl,#4914
		call	PRINTHL
		ld	de,Bd
;		jp	PRINT
		call	PRINT
;		jp	key_loop
		jr	read_cwhostname

your_ip_call	ld	hl,at_cwjap_def?	;default AP
		ld	de,#460C
		call	prn_ap_name_sig_def 

		ld	de,your_ip		;your IP
		ld	hl,#4900+40
		call	PRINTHL
		ld	de,spaces
		call	PRINT

		call	clear_rece_buf

		ld	hl,at_cifsr
		call	send_string

		ld	bc,#80
		push	bc
		ld	hl,RX_buf
		push	hl
		ld	de,#800
		call	receive_query
		pop	hl
		pop	bc
		ld	hl,RX_buf
		ld	de,RX_buf
		ld	bc,128
		call	at_quoted
		ret	c
yi2		ld	de,RX_buf
		ld	hl,#4900+40+9
		set	7,(ix+3)		;set print_other_info as already called
		call	PRINTHL

;read CWHOSTNAME
read_cwhostname
		ld	de,station_name
		ld	hl,#4812
		call	PRINTHL
		
		ld	hl,at_cwhostname
		call	send_string

		ld	bc,#80
		ld	hl,RX_buf
		push	hl
		ld	de,#800			;speed 0- did not help
		call	receive_query
;		call	receive_data_timeout
		pop	hl

		ld	de,dvojt
		call	look_for_string
		ret	nz			;not found
		inc	hl			;HL=start of the string to print	
		push	hl
		ld	de,eol
		call	find_required
		ld	(hl),0
		pop	de
;		ld	hl,#4820
;		call	PRINTHL
read_cw_ret	call	PRINT			;either #C3 for JP (and return) or #CD (for call and continue)

;display FW version
display_fw	ld	de,firmware
		ld	hl,#4700
		call	PRINTHL

		ld	hl,at_gmr
		call	send_string

		ld	bc,#FF
		ld	hl,RX_buf
		push	hl
		ld	de,#800			;speed 0- did not help
		call	receive_query
;		call	receive_data_timeout
		pop	hl

		ld	de,dvojt
		call	look_for_string
		ret	nz			;not found
		inc	hl			;HL=start of the string to print	
		push	hl
		ld	de,zavorka2
		call	find_required
		ld	(hl),0
		pop	de
		push	de
		call	PRINT

		ld	hl,#4719
		ld	de,sdk
		call	PRINTHL

		pop	hl			;buffer text		
		ld	de,eol
		call	find_required
	
		ld	de,dvojt
		call	find_required
		inc	hl
		push	hl
		ld	de,zavorka2
		call	find_required
		ld	(hl),0

;		pop	hl			;start of the text
;		push	hl
;		ld	de,_3_0_5
;		ld	de,_3_0_6
;		ld	bc,10
;		call	look_for_string

		pop	de			;start of text
		push	de
;		push	af			;ver1.6.- we do different evaluation of version	
		call	PRINT

		pop	hl
		ld	de,block_asci
		push	de
;		inc	hl
		ld	b,3
df2		ld	a,(hl)
		ld	(de),a
		inc	hl
		inc	hl
		inc	de
		djnz	df2
		ex	de,hl
		ld	(hl),b

		pop	de			;DE=start
		call	ConvRStr16
		ld	de,306
		or	a
		sbc	hl,de


;		pop	af
		ld	de,need_update
		jr	c,df1
;		jr	nz,df1
		ld	de,latest
df1		call	PRINT



read_cwmode	ld	hl,at_cwmode?
		call	send_string

		ld	bc,#FF
		ld	hl,RX_buf
		push	hl
		ld	de,#800			;speed 0- did not help
		call	receive_query
		pop	hl

		ld	de,plus
		call	look_for_string
		ret	nz			;not found
		ld	hl,#4736
		jp	PRINTHL
;		jp	 key_loop


change_wifi_mode
		ld	hl,at_cwmode?
		call	send_string

		ld	bc,#FF
		ld	hl,RX_buf
		push	hl
		ld	de,#800			;speed 0- did not help
		call	receive_query
		pop	hl

		ld	de,dvojt
		call	look_for_string
		ret	nz
		ex	de,hl
		ld	a,(hl)
		sub	#30
		dec	a
		jr	nz,chwm1
		ld	a,3

chwm1		ld	hl,at_cwmode+10
		add	#30
		ld	(hl),a
		ld	hl,at_cwmode
		call	ap_send_ok
		ret	nz
		jr	read_cwmode








set_rtc                 call next_timezone_input
                        ret c
		bit	5,(ix+0)		;test if wifi is connected to AP
		ld	hl,flag1
		set	4,(hl)			;print speed management info
		jr	z,srtc1
		res	4,(hl)			;we do not want speed management to print info
srtc1		call	speed_management
		set	4,(ix+0)		;PRINT again
		ld	(ix+6),#70+#30		;timeout for sntp server+cfg activation
		res	2,(ix+0)		;zone is plus

		ld	hl,at_cipsntpcfg	;place GMT shift to the command
		ld	de,RX_buf
		push	de
		ld	bc,16
		ldir
		inc	hl
		push	hl
		ld	h,c
                        ld a,(next_timezone)
		or	a
		jp	p,gmt_plus
;		cpl
		neg
		set	2,(ix+0)		;zone is minus

		ex	de,hl
		ld	(hl),"-"
		inc	hl
		ex	de,hl

;		ld	a,"-"
;		ld	(de),a
;		inc	de

gmt_plus	ld	l,a
		call	HL2ASCII
						;shift at place
		pop	hl
		ld	bc,50
		ldir		
		ex	de,hl
		ld	(hl),13
		inc	hl
		ld	(hl),10
		inc	hl
		ld	(hl),b			;comamnd at place


;		ld	hl,at_cwmode		;send AT commands to get time&date
;		call	send_string		;not needed here, already done in the start
;		ld	hl,ok
;		call	look_on_fly
;		ld	bc,1
;		jp	nz,error



;		ld	hl,RX_buf
		pop	hl
		push	hl
		call	send_string		;send AT CFG command from RXbuf

;		ld	hl,at_cipsntpcfg
;		call	send_string

		ld	hl,ok_
		call	ap_wait_line
		ld	c,8
;		ld	bc,8
		jp	nz,error_handler

		ld	de,gmt_shift		;print GMT shift
		ld	hl,(wind_adr)
		call	PRINTHL

		pop	hl			;HL=RXbuf
		ld	bc,16
		add	hl,bc
		ld	de,block_asci
		push	de
		ld	a,(hl)
		cp	"-"
		jr	z,gmts2
		ld	a,"+"
		ld	(de),a
		inc	de
gmts2		ld	bc,3
gmts1		ldi
		ld	a,(hl)
		cp	","
		jr	z,gmts_done
		ld	a,b
		or	c
		jr	nz,gmts1
		ld	c,4
		jp	error_handler
gmts_done		xor	a
		ld	(de),a
		pop	de
		call	PRINT
		
;		call	wifi_wait

activate_tz	ld	hl,at_cipsntpcfg?
		call	send_string
		ld	bc,#FF	;bounded RX+TX scratch area
		ld	hl,RX_buf
		push	hl
		call	receive_data_timeout
		pop	hl
		ld	de,time_zone_act	;look for "CFG:1"
		ld	bc,#FF	; bounded received config, including leading CR/LF
		call	look_for_string
		push	af
		dec	(ix+6)
		ld	c,7
;		ld	bc,7
		jp	z,error_handler		;timeout
		pop	af
		jr	nz,activate_tz
		





read_t_again	ld	hl,(HLKO+1)
		push	hl
		ld	de,wait_ntp
		ld	hl,#4B40
		call	PRINTHL
		pop	hl
		ld	(HLKO+1),hl

		ld	hl,at_cipsntptime
		call	send_string

		ld	bc,#FF	;bounded RX+TX scratch area
		ld	hl,RX_buf		;now come the awaited data/body, accept it
		call	receive_data_timeout
		push	hl
		ld	de,RX_buf+10
		or	a
		sbc	hl,de
		pop	hl
		jr	c,ntp_short_reply

		ld	bc,10			;seek for year 19xx
		or	a
		sbc	hl,bc
		ld	a,(hl)
		add	hl,bc
;		cp	"1"
		cp	"2"

ntp_short_reply	push	af
		push	hl
		ld	hl,(HLKO+1)
		push	hl
		ld	de,spaces
		ld	hl,#4B40
		call	PRINTHL
		pop	hl
		ld	(HLKO+1),hl
		pop	hl

		dec	(ix+6)
		jr	nz,rta1
		ld	hl,#4B80
		ld	de,ntp_timeout
		call	PRINTHL
		ld	c,2
;		ld	bc,2
		jp	error_handler

rta1		pop	af			;CP "1"
		jr	nz,read_t_again		;to repair "1970"error
;		call	wifi_unwait
;		jr	z,read_t_again

						;year 2xxx found, continue


		ld	bc,6			;HL=length of incoming data
		or	a			;Z=all OK, received data (body) in RX buffer
		sbc	hl,bc
		ld	(hl),0			;at the end 0 have to come to print it


		ld	de,STATUS+6		;we seek for ":"
		ld	bc,20
		ld	hl,RX_buf
		call	look_for_string
		ld	c,4
;		ld	bc,4
		jp	nz,error_handler
						;now, current time&date is on DE

		push	de			;DE=begin of time#date

		ld	hl,#4B80
		call	PRINTHL
						;print it

		pop	de
		push	de
		ex	de,hl			;now position zeros so you can start
		xor	a			;analysis
		ld	bc,3
		add	hl,bc
		ld	(hl),a
		inc	bc
		add	hl,bc
		ld	(hl),a
		dec	bc
		add	hl,bc
		ld	(hl),a
		add	hl,bc
		ld	(hl),a
		add	hl,bc
		ld	(hl),a
		add	hl,bc
		ld	(hl),a
		inc	bc
		inc	bc
		ld	(hl),a

		ld	bc,35
		ld	hl,days
		pop	de			;DE= start of date data retrieved by AT com.
		push	de
		call	find_required
		inc	de
		ld	a,(de)
		inc	de
		ld	(rtc_entry+3),a		;week days

		pop	de
		inc	de
		inc	de
		inc	de
		inc	de
		push	de
		ld	bc,5*12
		ld	hl,months
		call	find_required
		inc	de
		ld	a,(de)
		inc	de
		ld	(rtc_entry+5),a		;month

		pop	hl
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		push	hl
		call	convASCII2hex
		ld	(rtc_entry+4),a		;days (0-31)

		pop	hl
		inc	hl
		inc	hl
		inc	hl
		push	hl
		call	convASCII2hex
		ld	(rtc_entry+2),a		;hours

		pop	hl
		inc	hl
		inc	hl
		inc	hl
		push	hl
		call	convASCII2hex
		ld	(rtc_entry+1),a		;mins

		pop	hl
		inc	hl
		inc	hl
		inc	hl
		push	hl
		call	convASCII2hex
		ld	(rtc_entry),a		;secs

		pop	hl
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		call	convASCII2hex
		ld	(rtc_entry+6),a		;year







                        call next_rtc_write
                        jr nc,next_rtc_done
                        ld hl,#4B80
                        ld de,next_rtc_error
                        call PRINTHL
next_rtc_done           call akey
                        jp klAP_ret

;wrl_ret	call	wifi_unwait
;		call	akey
;		jp	klAP_ret+3
		
				
; Signed decimal timezone, no fractional hours: ESP AT range -12..+14.
next_timezone_input     call clear_edit_zone
                        ld de,next_timezone_prompt
                        ld hl,edit_zone1
                        call PRINTHL
                        push ix
                        ld ixh,3
                        call INPUT
                        pop ix
                        cp 4
                        jr z,next_timezone_cancel
                        call next_timezone_parse
                        jr c,next_timezone_input
                        ld (next_timezone),a
                        call clear_edit_zone
                        or a
                        ret
next_timezone_cancel   call clear_edit_zone
                        scf
                        ret
next_timezone_parse    ld a,(INLEN)
                        ld b,a
                        ld hl,INPBUFF
                        ld e,0
                        or a
                        jr z,next_timezone_bad
                        ld a,(hl)
                        cp '-'
                        jr nz,next_timezone_plus
                        inc e
                        jr next_timezone_skip
next_timezone_plus     cp '+'
                        jr nz,next_timezone_digits
next_timezone_skip     inc hl
                        dec b
next_timezone_digits   ld a,b
                        or a
                        jr z,next_timezone_bad
                        cp 3
                        jr nc,next_timezone_bad
                        ld d,0
next_timezone_digit    ld a,(hl)
                        sub '0'
                        cp 10
                        jr nc,next_timezone_bad
                        ld c,a
                        ld a,d
                        add a,a
                        ld d,a
                        add a,a
                        add a,a
                        add a,d
                        add a,c
                        ld d,a
                        inc hl
                        djnz next_timezone_digit
                        ld a,e
                        or a
                        ld a,d
                        jr z,next_timezone_positive
                        cp 13
                        jr nc,next_timezone_bad
                        neg
                        or a
                        ret
next_timezone_positive cp 15
                        jr nc,next_timezone_bad
                        or a
                        ret
next_timezone_bad      scf
                        ret
next_timezone           db 1
next_timezone_prompt    db "GMT offset (-12..14), EDIT=back:",0
next_rtc_error          db "RTC missing / I2C error",0

; DS1307, address 68h. Nominal 3.5MHz; 19T SCL high stays >4us in all timings.
; Write date/time first, then the RTC.SYS signature at 3Eh/3Fh (official 'ZX').
next_rtc_write         call next_i2c_start
                        jr c,next_rtc_fail
                        ld a,#D0
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        xor a
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        ld hl,rtc_entry
                        ld d,7
next_rtc_data          ld a,(hl)
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        inc hl
                        dec d
                        jr nz,next_rtc_data
                        call next_i2c_stop
                        call next_i2c_start
                        jr c,next_rtc_fail
                        ld a,#D0
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        ld a,#3E
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        ld a,'Z'
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        ld a,'X'
                        call next_i2c_byte
                        jr c,next_rtc_fail
                        jp next_i2c_stop
next_rtc_fail          scf
                        jp next_i2c_stop
next_i2c_start         ld bc,#113B
                        ld a,1
                        out (c),a          ; release SDA
                        dec b
                        out (c),a          ; release SCL
                        in a,(c)
                        rrca
                        ccf
                        ret c              ; SCL held low
                        inc b
                        in a,(c)
                        rrca
                        ccf
                        ret c              ; SDA held low
                        ld a,0
                        out (c),a          ; START
                        dec b
                        out (c),a
                        ret
next_i2c_stop          ld bc,#113B
                        ld a,0
                        out (c),a
                        dec b
                        ld a,1
                        out (c),a
                        inc b
                        out (c),a
                        ret                ; preserve carry (ACK/error)
next_i2c_byte          push de
                        ld e,a
                        ld d,8
next_i2c_bit           rl e
                        ld a,0
                        adc a,0
                        ld bc,#113B
                        out (c),a
                        dec b
                        ld a,1
                        out (c),a
                        ld a,0
                        out (c),a
                        dec d
                        jr nz,next_i2c_bit
                        inc b
                        ld a,1
                        out (c),a          ; release SDA for ninth ACK bit
                        dec b
                        out (c),a
                        inc b
                        in a,(c)
                        rrca               ; carry=1 on NACK
                        dec b
                        ld a,0
                        out (c),a
                        pop de
                        ret

days		db	"Mon",0,2,"Tue",0,3,"Wed",0,4,"Thu",0,5
		db	"Fri",0,6,"Sat",0,7,"Sun",0,1

months		db	"Jan",0,1,"Feb",0,2,"Mar",0,3,"Apr",0,4,"May",0,5,"Jun",0,6
		db	"Jul",0,7,"Aug",0,8,"Sep",0,9,"Oct",0,#10,"Nov",0,#11,"Dec",0,#12,0

rtc_entry	db	#55,#55,#55,#55,#55,#55,#55
			;secs, mins, hours, week day, day, month, year (all in hex)


/* 	;pro rucni input, zatim deaktivujeme
input		push	ix
		ld	ixh,3
		call	INPUT		;input 3 digit shift
		pop	ix		;valid range is <-11,13>

		cp	4
		ret	z		;user pressed CS+3, he aborted INPUT

		res	7,(ix+0)
		
		ld	de,INPBUFF
		ld	a,(de)
		cp	"-"
		jr	nz,not_minus
		inc	de
		set	7,(ix+0)

not_minus
		ld	a,(de)
nm1		cp	#30
		jr	c,inp_again
		cp	#39
		jr	nc,inp_again	
		inc	de
		ld	a,(de)
		cp	#20
		jr	nz,nm1


		bit	7,(ix+0)
		push	af
		ld	de,INPBUFF
		jr	z,eval_plus1
		inc	de

eval_plus1	call	ConvRStr16

		pop	af
		ld	a,l
		jr	z,eval_plus

		cp	12
		jr	c,gmt_range_ok
		jr	inp_again


eval_plus	cp	14
		jr	c,gmt_range_ok

inp_again	jr	input		;dopnit text

		

gmt_range_ok	ld	hl,gmt_shift
		push	hl
		ld	b,4
zero_gmt_range	ld	(hl),0
		inc	hl
		djnz	zero_gmt_range

		ld	hl,INPBUFF	;nyni se musi obsah INPBUFF naldirovat k prikazu
		pop	de		;DE=gmt_shift
		ld	bc,4
ldi_gmt_range	ldi
		ld	a,(hl)
		or	a
		jr	nz,ldi_gmt_range

;zde bude ret do hlavn  rutiny
		

		jr	stack_pointer+3	
*/

block_asci	ds	10			;blocks converted to ASCII, (used by progress display)
		db	0



error_handler	set	4,(ix+0)		;PRINT again
		ld	h,0
		ld	l,c
		ld	de,block_asci
		push	de
		call	HL2ASCII
		ex	de,hl
		ld	(hl),0

		call	clear_edit_zone

		ld	hl,edit_zone2
		ld	de,error_txt
		call	PRINTHL
		pop	de
		call	PRINT

		call	wifi_unwait		;wrl_ret
		call	akey

klAP_ret	call	undraw_cursor		;return from AP selection
		call	wind_cls
		call	clear_edit_zone
;		call	clear_edit_zone
;		jp	key_loop		;puvodni klap_ret skakala na key_loop
;		jp	key_loop-3		;-3= including print_other_info
		ld	sp,basic_end-2
		ret				;jump back to "error_handler_loop"

;		jp	wrl_ret		;complete return

allok		ld	bc,0

;	IF standalone
	IFDEF standalone
		push	bc
	ENDIF

quit		bit	3,(ix+0)			;set Wifi on/off on exit
		push	af
		call	z,wifi_off
		pop	af
		scf
		call	nz,wifi_on

;	IFN standalone
	IFNDEF standalone

		ld	bc,port_select			;set machine #FF
		xor	a
		out	(c),a
		inc	b
		dec	a
		out	(c),a
		inc	a
		out	(#07),a				;page back MB03+
		inc	a
		out	(#47),a				;JP back to MB03; is prepared

	ENDIF


                        ld bc,#243B
                        ld a,7
                        out (c),a
                        inc b
return_speed            ld a,0
                        out (c),a

;	IFN standalone
	IFNDEF standalone
		rst	0		;restart
	ENDIF

;	IF standalone
	IFDEF standalone
		pop bc			;BC=error code, this is a good return to BASIC
stack_pointer           ld sp,#5555
restore_ix              ld ix,0
restore_iy              ld iy,0
                        exx
restore_alt_hl          ld hl,0
                        exx
                        ei
                        ret		;return to BASIC, for the moment
	ENDIF






;****************************************************************
;****************************************************************
;****************************************************************


;PARSING
;look for a string in received bytes string, for receive string evaluation purposes
;IN=HL start of the memory area, DE=start of the string we look for, must end with 0, BC=max.len of searched memory, OUT=Z=found, HL=start address of found string in memory, DE=byte coming after found string, NZ=string not found
;10)
look_for_string	ld a,b
		or c
		jr nz,lfs_nonempty
		or 1
		ret
lfs_nonempty	ld (lfs5+1),sp
		set 0,(ix+0)

lfs3		ld a,(de)
		cp (hl)
		jr z,lfs_match

		bit 0,(ix+0)		;NZ=no match, was already matching?
		inc hl			;new
		jr nz,lfs2
		dec hl			;new
		pop de			;Z=was matching, now not anymore, renew looked for string
		pop de			;DE=start of searched string
		inc bc
lfs2		set 0,(ix+0)
;		inc hl			;new


lfs1		dec bc
		ld a,b
		or c
		jr nz,lfs3
		inc c			;BC max length reached, set NZ & return
		jr lfs5	

		



lfs_match	bit 0,(ix+0)
		jr z,lfs_alrea_match
		res 0,(ix+0)		;Z=match found, push address
		push de
		push hl

lfs_alrea_match	inc hl
		inc de
		ld a,(de)
		or a
		jr nz,lfs1		;continue macthing if string continues

		ld d,h
		ld e,l			;DE=byte coming after found string
		pop hl			;HL=start address of found string in memory

lfs4		dec bc
		bit 0,(ix+0)
lfs5		ld sp,#5555
		ret			;Z/NZ






;IN=HL=start of looked for string, must end with 0
;OUT=Z=string found, NZ=string not found
;11)
look_on_fly	exx
		ld	bc,0
		exx
		ld	e,#FF		;e= flag, Z=found,NZ=not found
		ld	b,e
		ld	c,e		;BC=timeout
lof3		push	hl
lof1		dec	bc		;bugfix 0.3
lof5		scf
		call	rece_byte
		jr	nz,lof4

		exx			;Z= no byte to receive. ESP can just breathe out and then continue
		dec	bc
		ld	a,c
		or	b
		exx
		jr	z,lofend	;Z=really, no byte to collect
		jr	lof5

lof4		cp	(hl)
		ld	e,0
		jr	z,lof2		

		dec	e		;NZ,char does not match, bring another byte
		pop	hl
		ld	a,b		;max of 65535 unsucessfull tries
		or	c
		jr	z,lofend1
		jr	lof3		

lof2		inc	hl
		ld	a,(hl)
		or	a
		jr	nz,lof1		;still not end, continue search
		
		
lofend		pop	hl
lofend1		inc	e
		dec	e
		ret			;Z/NZ




;RECEIVING
;IN=BC=max.length of data to receive, HL=start of received data, OUT=Z= desired length of data received,opravit vystupni flagy Z/NZ nyn  neur eny

;7)
receive_data_timeout
		ld de,#290		;timeout, if #80, only app. first #500 bytes carried correctly
		jp receive_query
receive_query	push bc
		call receive_data1
		pop bc
		ret
receive_data1	ld (receive_reload+1),de
receive_loop	ld a,b			;bios1.2, timeout have to increase to #200
		or c
		ret z			;Z=length reached, return
		scf
		call rece_byte
		jr nz,rd1
		dec de			;Z=no byte to receive
		ld a,e			;DE=timeout, in case there is receive interuption
		or d
		jr z,receive_pad
		jr receive_loop	;do not decrease BC, as no data came in

rd1		ld (hl),a
		inc hl
		dec bc
receive_reload	ld de,0	;restart the requested inter-byte timeout
		jr receive_loop

;Clear only the unread tail; preserve HL=end of data and BC=unread count.
receive_pad	ld a,h
		cp HIGH start_address
		ret c	;AP scan uses its received length, not padded capacity
		push hl
		push bc
receive_pad_loop ld (hl),0
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,receive_pad_loop
		pop bc
		pop hl
		ret



;SENDING
;IN=HL string (ends with 0), OUT=Z=string has been sent, NZ=not sent, timeout
;1)
send_string	push hl			;print it first
		ld d,h
		ld e,l
		call PRINT
		pop hl

		ld de,0			;maximum timeout

ss2		ld a,(hl)
		or a
		ret z			;Z=end of string

ss1		scf
		call send_byte
		jr nc,ss3
		ld b,a
		ld a,3
		out (254),a		;magenta border= TX line is busy.....
		dec de
		ld a,d
		or e
		jr nz,ss4
		inc e
		ret
ss4		ld a,b			;maybe some timeout could be added here
		jr ss1

ss3		inc hl
		xor a
		out (254),a
		jr ss2


	IFUSED send_data

;IN=HL start of data, BC=data len, OUT=Z=data has been sent
;2)
send_data	ld a,b
		or c
		ret z			;Z=len of data in BC sent
		ld a,(hl)
		or a
		ret z
sd1		scf
;		ld e,a
		call send_byte
;		ld a,e
		jr c,sd1
		inc hl
		dec bc
		jr send_data

	ENDIF


;OTHERS
	
;16)
ConvRStr16
;===============================================================
;http://z80-heaven.wikidot.com/math#toc32
;Input: 
;     DE points to the base 10 number string in RAM. 
;Outputs: 
;     HL is the 16-bit value of the number 
;     DE points to the byte after the number 
;     BC is HL/10 
;     z flag reset (nz)
;     c flag reset (nc)
;Destroys: 
;     A (actually, add 30h and you get the ending token) 
;Size:  23 bytes 
;Speed: 104n+42+11c
;       n is the number of digits 
;       c is at most n-2 
;       at most 595 cycles for any 16-bit decimal value 
;===============================================================

     ld hl,0          ;  10 : 210000 
ConvLoop:             ; 
     ld a,(de)        ;   7 : 1A 
     sub 30h          ;   7 : D630 
     cp 10            ;   7 : FE0A 
     ret nc           ;5|11 : D0 
     inc de           ;   6 : 13 
                      ; 
     ld b,h           ;   4 : 44 
     ld c,l           ;   4 : 4D 
     add hl,hl        ;  11 : 29 
     add hl,hl        ;  11 : 29 
     add hl,bc        ;  11 : 09 
     add hl,hl        ;  11 : 29 
                      ; 
     add a,l          ;   4 : 85 
     ld l,a           ;   4 : 6F 
     jr nc,ConvLoop   ;12|23: 30EE 
     inc h            ; --- : 24 			
     jr ConvLoop      ; --- : 18EB



;17)
;IN=HL=number, OUT=DE=address with the string
HL2ASCII		res 7,(IX+0)		;Leading zero suppression
HL2ASCII_00000		ld bc,10000
			call string_dl
			ld bc,1000
			call string_dl
			ld bc,100
			call string_dl
			ld bc,10
			call string_dl
			ld a,l
			add a,'0'
			LD (DE),A
			INC DE
			RET
			
string_dl:		ld a,'0'-1

string_lp2:		inc a
			or a
			sbc hl,bc
			jr nc,string_lp2
			add hl,bc
			CP '0'
			JR Z,string_store

			SET 7,(IX+0)		;Had something other than zero

string_store:		BIT 7,(IX+0)		;Test if still leading zeros
			RET Z						
			LD (DE),A		;If not store it	
			INC DE
			RET	






	IFUSED wait_long
;18)
wait_long	ld	b,3		;wait long time, DE delay fixed (3x 65536 times)
wait_long_def	call	wait_short	;wait long time, DE delay suer defined (Bx 65536 times), IN=B=delay
		djnz	wait_long_def
		ret

wait_short	ld	de,0		;wait short time, DE delay fixed (65536 times) (tady by mela stacit polovicni hodnota tedy #8000)!!!!
wait_short_def	dec	de		;wait short time, DE delay user defined,IN=DE=delay
		ld	a,d
		or	e
		jr	nz,wait_short_def
		ret

	ENDIF




;29)input: timeout in (ix+6), output, Z="OK" found, NZ=answer "OK" not found
send_at_check_ok
		call	wifi_wait
		ld	hl,at
		call	send_string
		ld	c,28
;		ld	bc,28
		jp	nz,error_handler

;		ld	de,#100			;when it is away, it speeds up the search significantly
;		call	wait_short_def

		ld	hl,RX_buf
		ld	bc,20
		push	hl
		push	bc
		ld	de,RX_buf+1		;clear RX_buf before reading bytes to it
		ld	(hl),0
		ldir
		pop	bc
		pop	hl
		push	hl
		push	bc
		call	receive_data_timeout	;much quicker than look_on_fly
		pop	bc
		pop	hl
		call	wifi_unwait
		ld	de,ok
;		jp	look_for_string
		call	look_for_string
		ret	z
		dec	(ix+6)
		jr	nz,send_at_check_ok
		inc	c			;NZ=OK not found
		ret


;40) OUT CY 0=OK, 1= speed not supported, set and print UART speed
; Next CPU state and known UART speed. The BIOS query is deliberately read-only.
next_init               ld bc,#243B
                        ld a,7
                        out (c),a
                        inc b
                        in a,(c)
                        and 3
                        ld (return_speed+1),a
                        xor a             ; 3.5 MHz keeps existing polling timeouts
                        out (c),a
                        ld a,7            ; known host UART baseline, 115200
                        scf
                        call set_baud
                        ld a,7
                        ld (next_baud),a
                        ret
get_baud                ld a,(next_baud)
                        cp 15
                        jr nc,next_unknown_baud
                        or a              ; query nominal BC:E only, no UART write
                        jp set_baud
next_unknown_baud       ld bc,0
                        ld e,c
                        ld a,#FF
                        scf
                        ret
next_baud               db #FF

set_print_speed	scf
		push	af
		call	set_baud
                        jr c,next_set_failed
                        ld (next_baud),a
next_set_failed
		pop	de
		ld	a,d		;A=speed 0-23 we set
print_speed	push	af
ps2		ld	de,TX_buf
		push	de
		ld	h,0
		ld	l,a
		call	HL2ASCII
		ld	a,32
		ld	(de),a
		inc	de
		ld	(de),a
		xor	a
		inc	de
		ld	(de),a
		pop	de
		ld	hl,(HLKO+1)
		push	hl
		ld	hl,speed_pos+7+8
;		ld	(HLKO+1),hl
		call	PRINTHL
		pop	hl			;return print position
		ld	(HLKO+1),hl
		pop	af			;CY/NC
		ret



;48)
convASCII2hex
;IN=HL ASCII number address (2 digits) eg. hl,14
;OUT=A=#14
		ld	a,(hl)
		and	%00001111
		sla	a
		sla	a
		sla	a
		sla	a
		ld	e,a
		inc	hl
		ld	a,(hl)
		and	%00001111
		or	e
		ret

;49) clear whole screen
cls_4000	ld	hl,16384
		push	hl
		ld	de,16385
		ld	bc,6144
		ld	(hl),0
		ldir
		ld	bc,768
		ld	(hl),7
		ldir
		pop	hl
		ret

;50) clear 9 lines, if called from "cls_9_hl", 9 lines starting from HL will be cleared
;if called from "cls_9_lines", the input must be HL=starting address, and B= number of micro lines to clear
cls_9		ld	hl,#4000+(32*3)
cls_9_hl	ld	b,8*9
cls_9_lines	push	hl
		xor	a
		ld	e,#20
cls_91		ld	(hl),a
		inc	hl
		dec	e
		jr	nz,cls_91
		pop	hl
		call	DOWNHL
		djnz	cls_9_lines
		ret

;54) clears edit zone (2 bottom lines)
clear_edit_zone	ld	b,2*8
		ld	hl,#50C0
		jr	cls_9_lines


		
;51) INPUT:de=print position, 2,(ix+3)=0 default AP, 1=current AP
prn_ap_name_sig	ld	hl,at_cwjap_cur?	;find out current AP
;;;		set	2,(ix+3)			
;;;		jr	prnasd1
prn_ap_name_sig_def
;;;		res	2,(ix+3)
prnasd1		push	de			;DE=print position
		call	send_string
;		ld	bc,1			;error to be solved
;		jp	nz,error

		ld	hl,RX_buf		;receive the answer to RX_buf
		ld	bc,128
		push	hl
		push	bc

		ld	a,(ix+2)
		cp	3
		jr	nc,prap1
		ld	de,#D00			;experimental timeout, it works!!
		call	receive_data1		;for speeds <3 we need bigger receive timeout
		jr	prap6


prap1		call	receive_data_timeout

prap6		pop	bc			;BC=100
		pop	hl			;HL=RX_buf


		push	hl			;HL=RX_buf
		push	bc			;BC=100

		ld	de,ok			;new concept, look for "OK", if not then "No AP"
		call	look_for_string
		jr	z,ap_answ_found


prap2		pop	bc			;BC=100, OK not found
		pop	de			;RX_buf
prap5		pop	hl			;print position


		push	hl			;print position
		ld	de,spaces
		call	PRINTHL

		ld	de,no_ap
		pop	hl			;HL=print position
		res	5,(ix+0)		;probably not needed
;;;		call	PRINTHL
		jp	PRINTHL			;No AP
;;;
/*
prap_sub	push	hl
		push	af			;preserve zerro
		ld	hl,flag2		;Z=AP name found, NZ= not found
		bit	2,(hl)			;bit 2, current or default AP
		jr	nz,prap_sub1

		pop	af
		set	4,(hl)			;bit 4, default AP
		jr	z,prap_sub2
		res	4,(hl)
		pop	hl
		ret

prap_sub1	pop	af
		set	6,(hl)			;bit 6, current AP
		jr	z,prap_sub2
		res	6,(hl)
prap_sub2	pop	hl
		ret
;;;
*/
						;check type of answer	
ap_answ_found	pop	bc			;BC=100
		pop	hl			;HL=RX_buf
		push	hl
		push	bc
		ld	de,no_ap
		call	look_for_string
		jr	z,prap2			;"No AP" found, end
		pop	bc			;BC=100
		pop	hl			;HL=RX_buf

		ld	de,dvojt
		call	look_for_string
		jr	nz,prap5		;":" not found, probably nonsence returned
						;due to eg. speed module will not communicate
;		call	prap_sub		;AP name found, set flag
		ex	de,hl
		ld	de,RX_buf
		call	at_quoted
		jp	c,prap5
		pop	bc	;screen position
		push	hl	;position after the SSID closing quote
		ld	h,b
		ld	l,c
		ld	de,RX_buf
		call	PRINTHL
		pop	hl
		inc	hl	;skip the comma before BSSID
		;Recompute a safe remaining bound after the print call.
		push	hl
		ld	de,RX_buf+128
		ex	de,hl
		or	a
		sbc	hl,de
		ld	b,h
		ld	c,l
		pop	hl
		ld	de,carka
		call	find_required
		ex	de,hl
		ld	de,carka
		call	find_required
		push	hl	;RSSI separator
		inc	hl
;test plusove hodnoty				;HL=start cisla, nebo minus
		ld	a,(hl)
		cp	"-"
		jr	nz,prap3
		inc	hl
prap3		ex	af,af'			;AF preserves flag Z/NZ
		ex	de,hl
		call	ConvRStr16
		xor	a
		ld	(de),a
		ex	af,af'
		jr	z,prap7			;Z=old correct FW 305 or lower

		xor	a
		sub	l
		sub	4	;4=more precise	;wrong value in FW in 306, needs correction vallue-256
		ld	l,a			;L=signal intensity
		pop	de
		push	de			;DE=start of print position
		inc	de
		ld	a,"-"
		ld	(de),a
		inc	de
		push	hl
		call	HL2ASCII
		xor	a
		ld	(de),a
		pop	hl			;L=signal intensity


;prap7		ld	c,4			
;		call	look_for_string
;		jr	z,prap3
;		pop	hl			;start of signal intensity
;		push	hl

;prap4		ld	a,(hl)
;		cp	#D
;		jr	z,prap3
;		inc	hl
;		jr	prap4
;
;prap3		ld	(hl),0
;		pop	de			;print signal inensity value
;		push	de
;		call	PRINT
;		pop	de
;		inc	de
;		inc	de
;		call	ConvRStr16		;ASCII to HL
;		ld	a,l
;test plusove hodnoty
;		ex	af,af'
;		ld	a,l
;		jr	z,prap8
;		sub	0

prap7		pop	de
		push	hl
		call	PRINT
		pop	hl
		ld	a,l


prap8		ld	de,excellent
		cp	50			;print text level of signal intensity
		jr	c,prn_sig_txt
		ld	de,good
		cp	60
		jr	c,prn_sig_txt
		ld	de,fair
		cp	70
		jr	c,prn_sig_txt
		ld	de,poor
		
prn_sig_txt	call	PRINT
		ld	de,spaces+25
		jp	PRINT

;52) gets status (if wifi is connected to AP or not). OUT=Z=NO, NZ=YES, and sets the AP flag
;since 0.91 routine runs only 1x, no timeout. And no finding out of AP. this happens in
;prn_ap_name_sig
;this routine only print STATUS with number. And from 0,91 does not return with Z/NZ
get_status	call	clear_rece_buf
		ld	hl,cipstatus		;find out, if module connected to wifi
		call	send_string
;		ld	bc,1
;		jp	nz,speed_m_error	;spatne, zasobnik!!!

		ld	hl,RX_buf		;receive the answer about STATUS to RX_buf
		ld	bc,#80
;		ld	bc,20
		push	hl
		push	bc

		ld	a,(ix+2)
		cp	3
		jr	nc,gs1
		ld	de,#500			;experimental timeout, it works!!
		call	receive_data1		;for speeds <3 we need bigger receive timeout
		jr	gs2		

gs1		call	receive_data_timeout

gs2		pop	bc		;BC=20
		pop	hl		;HL=RX_buf

		push	hl
		push	bc
		ld	de,ok		;look for OK in the answer
		call	look_for_string
		jr	z,gs5


		pop	hl
		pop	bc
gs4		res	5,(ix+0)
		ld	de,STATUS	;OK not found
		ld	hl,#4300+9
		call	PRINTHL
		ld	de,unknown
		call	PRINT
		ld	de,spaces+8
		jp	PRINT


gs5		pop	bc		;BC=20
		pop	hl		;HL=RX_buf
		ld	de,STATUS
		call	look_for_string
		jr	nz,gs4

		push	hl		;HL=RXbuf for print
		ld	h,d
		ld	l,e
		ld	b,(hl)		;B= status number ("2"-"5")
		inc	de
		xor	a
		ld	(de),a

		pop	de		;DE=RX_buf for print
		push	bc		;B= status number ("2"-"5")
		ld	hl,#4300+9		;print STATUS
		call	PRINTHL
		pop	af			;A= status number ("2"-"5")
						;print result description
		ld	hl,flag1
		set	5,(hl)		;NZ=status "5" not found, wifi is connected to AP
		ld	de,cipstatus_2
		cp	"2"
		jr	z,gs3
		ld	de,cipstatus_3
		cp	"3"
;		jr	z,gs6
		jr	z,gs3
		ld	de,cipstatus_4
		cp	"4"
		jr	z,gs6
		ld	de,cipstatus_5
gs6		res	5,(hl)
gs3		call	PRINT
		ld	de,spaces+20
		jp	PRINT
	
		

;53) sets speed 155200 Bd on module and UART
set_def_wifi_speed

		ld	a,7
		jr	set_ud_speed_a


;55) a key
akey		ld	de,akey_txt
		ld	hl,edit_zone2+#30
		push	hl
		call	PRINTHL
		call	KEYSCAN
		pop	hl
		push	af
		ld	de,spaces+17
		call	PRINTHL
		pop	af
		or	a
		jr	z,akey
		ret

;56) wifi_wait/unwait	signals, that we wait for wifi
wifi_wait	ld	a,15
		jr	wifi_unwait1
wifi_unwait	ld	a,7
wifi_unwait1	ld	(23295),a
		ret

;57) align speed on UART and module, speed taken from IX+2. If IX+2=255, align at max MBFW speed. Or speed taken from A,
; then call set_user_defined_speed_a
;mostly for usage in SM2.0
;INPUT=D=currently aligned speed. If D=255 continue with speed align, if 0-23 compare with
;speed you want to align, if same, do not continue.
set_ud_speed
		ld	a,(ix+2)
		inc	a
		jr	z,set_mspeed_mbfw
		dec	a
		jr	set_ud_speed_a
set_mspeed_mbfw        ld a,(ix+8)       ; Next maximum is BIOS index 14

set_ud_speed_a	cp	15			;Next BIOS index 0..14
		ld	c,33
;		ld	bc,33
		jr	nc,suds5		;NC=speed >23, error
						
		ld	b,a			;A=speed to which we want align UART and module
		ld	c,b			;C=speed to which we want align UART and module
		cp	d			;D=currently aligned speed
		ret	z			;Z=speed we want is already aligned
		
		ld	hl,speed_table		;find the speed eg. "16= 3456000"
		or	a
		jr	z,suds2
sudsa1		ld	a,(hl)
		or	a
		inc	hl
		jr	nz,sudsa1
		djnz	sudsa1
suds2		ld	a,(hl)			;HL= Baud speed (eg. "3456000")
		cp	" "
		inc	hl
		jr	nz,suds2
				

		push	bc			;C= UART speed we want

		ld	de,TX_buf		;now prepare AT comand to TX_buf
		push	de
		push	hl			;HL=start of eg "3456000"
		ld	hl,uart
		ld	bc,12
		ldir

		pop	hl			;HL=start of eg "3456000"		
		push	hl
suds3		ld	a,(hl)
		or	a
		inc	bc
		inc	hl
		jr	nz,suds3
		dec	bc
		pop	hl
		ldir

		ld	hl,_8100
		ld	bc,10
		ldir		
		ex	de,hl
		ld	(hl),0
		
		pop	hl
		call	send_string	;set user defined speed on the module via AT+UART+CUR

		ld	hl,ok_		;for speeds<3 seems to work
		call	ap_wait_line	;correct answer OK means, we aligned speeds sucesfully

		pop	de
;		ld	bc,31		;OK not received in answer
		ld	c,31
		jr	nz,suds1
		

		ld	a,e			;A= UART speed we want
		call	set_print_speed		;set the desired speed in UART
		ret	nc			;NC=set sucessfully

		ld	c,32
;		ld	bc,32

suds1		push	bc
		ld	a,e
		call	set_print_speed
		call	print_bauds
		pop	bc

suds5		pop	hl
		jp	error_handler


; Copy counted user text to TX, quoting special AT string characters.
; Four bytes remain reserved for closing quote, CR, LF and zero.
at_escape
		ld	a,b
		or	c
		ret	z
		ld	a,(hl)
		inc	hl
		dec	bc
		cp	34
		jr	z,at_escape_prefix
		cp	44
		jr	z,at_escape_prefix
		cp	92
		jr	nz,at_escape_byte
at_escape_prefix
		push	af
		ld	a,92
		call	at_emit
		jr	c,at_escape_pop_bad
		pop	af
at_escape_byte
		call	at_emit
		ret	c
		jr	at_escape
at_escape_pop_bad
		pop	af
		scf
		ret
at_emit
		push	hl
		push	af
		ld	hl,TX_buf+208
		or	a
		sbc	hl,de
		jr	c,at_emit_bad
		jr	z,at_emit_bad
		pop	af
		pop	hl
		ld	(de),a
		inc	de
		or	a
		ret
at_emit_bad
		pop	af
		pop	hl
		scf
		ret
at_input_error
		ld	c,1
		jp	error_handler
; BC is the remaining source length; carry means absent/truncated field.
at_char
		ld	a,b
		or	c
		scf
		ret	z
		ld	a,(hl)
		inc	hl
		dec	bc
		or	a
		scf
		ret	z
		or	a
		ret
at_quoted
		call	at_char
		ret	c
		cp	34
		jr	nz,at_quoted
at_quote_body
		call	at_char
		ret	c
		cp	34
		jr	z,at_quote_end
		cp	92
		jr	nz,at_quote_copy
		call	at_char
		ret	c
at_quote_copy
		cp	32
		ret	c
		ld	(de),a
		inc	de
		jr	at_quote_body
at_quote_end
		xor	a
		ld	(de),a
		ret
; Normalized AP entries use byte 1, not a comma occurring in the SSID.
ap_separator
		ld	bc,#2100
ap_separator_next
		ld	a,(hl)
		cp	1
		jr	z,ap_separator_done
		or	a
		jr	z,at_field_bad
		inc	hl
		inc	c
		djnz	ap_separator_next
at_field_bad
		scf
		ret
ap_separator_done
		ld	b,0
		or	a
		ret
find_required
		call	look_for_string
		ret	z
		ld	c,9
		jp	error_handler
ap_scan_end	dw 0
ap_cwlap	db "+CWLAP:",0
;commands
at		db "AT",#D,#A,0
ate0		db "ATE0",#D,#A,0
cipmux		db "AT+CIPMUX=",0
cipstatus	db "AT+CIPSTATUS",#D,#A,0
uart		db "AT+UART_CUR="
;_1152000	db "1152000"
;_3456000	db "3456000"	
_8100		db ",8,1,0,0",#D,#A
at_cwmode?	db "AT+CWMODE?",#D,#A,0
at_cwmode	db "AT+CWMODE=1",#D,#A,0	
at_cipsntpcfg?	db "AT+CIPSNTPCFG?",#D,#A,0
at_cipsntpcfg	db "AT+CIPSNTPCFG=1,",0
sntp_servers	db 44,34,"tik.cesnet.cz",34,44,34
		db "time.nist.gov",34,44,34,"cz.pool.ntp.org",34,#D,#A,0
at_cipsntptime	db "AT+CIPSNTPTIME?",#D,#A,0
at_rst		db "AT+RST",#D,#A,0
at_cwjap_cur?	db "AT+CWJAP_CUR?",#D,#A,0
at_cwjap_def?	db "AT+CWJAP_DEF?",#D,#A,0
at_autocon	db "AT+CWAUTOCONN?",#D,#A,0
at_uart_def	db "AT+UART_DEF?",#D,#A,0
at_cwlapopt	db "AT+CWLAPOPT=1,6",#D,#A,0
at_cwlap	db "AT+CWLAP",#D,#A,0
at_cwjap_join	db "AT+CWJAP_CUR=",#22,0
at_cwqap	db "AT+CWQAP",#D,#A,0
at_cifsr	db "AT+CIFSR",#D,#A,0
at_gmr		db "AT+GMR",#D,#A,0
at_cwhostname	db "AT+CWHOSTNAME?",#D,#A,0
at_ciupdate	db "AT+CIUPDATE",#D,#A,0
at_restore	db "AT+RESTORE",#D,#A,0

;answers
STATUS		db "STATUS:",0
sendok		db "SEND "
ok		db "OK"
eol		db #D,#A,0
eoleol		db #D,#A
		db #D,#A,0
dvojt		db ":",0
carka		db ",",0
uvoz		db 34,0
zavorka		db ")",0
zavorka2	db "(",0
ok_		db "OK",0
plus		db "+",0
time_zone_act	db "CFG:1",0
answ_cwjap	db "+CWJAP",0
no_ap		db "No AP",0
ready		db "ready",0
e1		db "E:1",0
e2		db "E:2",0
e3		db "E:3",0
e4		db "E:4",0

;texts
speed		db "Current speed:",0
gmt_shift	db "GMT shift: ",0
module_no_aswer	db "..speed aligned, but no answer from module..",0
spaces		db "                                 ",0
wait_ntp	db "Waiting for server...",0
ntp_timeout	db "NTP server timeout. Try again.",0
wifi_reset	db "Resetting Wifi...",0
disconnect	db "DISCONNECT",0
need_update	db " (need update)",0
latest		db " (latest)",0
;_3_0_6		db "3.0.6",0
;_3_0_5		db "3.0.5",0
update_in_prog	db "..update in progress..",0
update_warn	db "Update resets the module into factory settings!!",0

/*
;		IF element=0
		IFNDEF element
title		db "Wifi setup MB03+, v1.6, Hood, 11/2021- 04/2025",0
		ENDIF

;		IF element=1
		IFDEF element
title		db "Wifi setup eLeMeNt ZX, v1.6, Hood, 11/2021- 04/2025",0
		ENDIF
*/

title                   db "WiFi Setup 1.8 ZX Next, Hood, 11/2026",0

title_len	equ $-title-1
title_col	equ (64-title_len)/2	;4-pixel character grid, round left for odd lengths
error_txt	db "error=",0
set_speed_txt	db "V- set speed",0
disconn_AP_txt	db "D- disconnect from AP",0
reset_wifi_txt	db "R- restart WiFi",0
press_set_rtc	db "S- set RTC",0
press_psw_s_h	db "P- psw ",0
press_run_term	db "T- run terminal",0
upgrade_firm	db "F- update firmware",0
new_name	db "N- new name",0
change_mode	db "M- mode",0
press_reset	db "Q- quit",0
;	IF standalone
	IFDEF standalone
		db 0
	ENDIF
	
;	IFN standalone
	IFNDEF standalone
		db " & RESET",0
	ENDIF
        IFNDEF ZXNEXT
wifi_on_exit	 db "W- wifi on quit: ",0
        ENDIF
set_ap		db "A- connect to AP",0
wifi_on_off	db "Wifi ON: ",0
on		db "ON ",0
off		db "OFF",0
show		db "show",0
hide		db "hide",0
setting_speed	db "setting speed...",0
con_2_AP	db "connecting to AP...",0
current_ap	db "current AP: ",0
akey_txt	db " ..press a key..",0
default_ap	db "Default AP: ",0
auto_ap		db "Auto AP: ",0
station_name	db "Station name: ",0
firmware	db "Firmware: AT: ",0
sdk		db "SDK: ",0
def_wifi_speed	db "Default wifi speed: ",0
your_ip		db "Your IP: ",0
excellent	db ",Best",0
good		db ",Good",0
fair		db ",Fair",0
poor		db ",Poor",0
Bd		db " Bd. ",0
ent_psw		db "Enter password for ",0
cwjap_err_1	db "..connection timeout",0
cwjap_err_2	db "..wrong password",0
cwjap_err_3	db "..cannot find the target AP",0
cwjap_err_4	db "..connection failed",0
already_connect	db "You are already connected to ",0
do_you_want_rec	db "Do you want to reconnect to ",0
yesno		db " Yes/No?",0
connect_success db "New connection succesful",0
control_keys	db "Use arrows, ss+ENT for current AP, EDIT to cancel.",0
cipstatus_2	db "= connected to AP, IP is obtained",0
cipstatus_3	db "= created TCP/UDP transmission",0
cipstatus_4	db "= TCP/UDP transmission diconnected",0
cipstatus_5	db "= does NOT connect to AP",0

mbfw		db "max speed index=",0

/*
;		IF element=0
		IFNDEF element
mbfw		db "MBFW= ",0
		ENDIF

;		IF element=1
		IFDEF element
mbfw		db "ELFW=",0
		ENDIF
*/

speed_table	db "0= 2400",0
		db "1= 4800",0
		db "2= 9600",0
		db "3= 19200",0
		db "4= 31250",0
		db "5= 38400",0
		db "6= 57600",0
		db "7= 115200",0  ;(default at reset)
		db "8= 230400",0
		db "9= 460800",0
		db "10= 576000",0
		db "11= 921600",0
		db "12= 1152000",0
		db "13= 1500000",0
		db "14= 2000000",0
contr_k_speed	db "Use arrows, ENT select, EDIT to cancel.",0
sel_spd_ask_txt	db "Speed not supported by module, set it anyway?",0
unknown		db " unknown..",0

;flags=IX+0
flag1		db 8		;see start of the code, 2=SSL connection,0=TCP
AP_count	db #55		;IX+1= number of APs in the memory
;ud_speed	db 7		;test pro esp32 pro honzy, nastavi se rachlost 115200 natvrdo
ud_speed	db #FF		;speed management2.0. Here is speed we want (0-23),#FF=not defined
flag2		db 0		;IX+3, print send command,0=NO, 1=YES
		db 0		;IX+4 used to indicate which MB wifi is used, bit 0=mb wifi no, 1=mb wifi yes
;		db #20		;IX+4, not valid.....(bit 0=AT+RST or AT+RESTORE?,0=AT+RST, 1=AT+RESTORE)
flag3		db 1		;IX+5, show/hide pasword when typing, bit 0 (0=hide,1=show)
		db #55		;IX+6, timeout for initi wifi speed management (used on more places)
		db #55		;IX+7, uart speed currently set in HW (0-23 speed set, 255 speed not set)
		db #55		;IX+8, maximum speed for bios (counted from FW)
		db #55		;IX+9, =buffer length counter for upload
		db #55		;IX+10, pointer to AP list, starts with 1	
cursor_w_stadr	dw #5960	;start address of cursor window for AP list
cursor_w_curad	dw #5960	;current address of cursor window
cursor_cur_pos	db #55		;IX+15, current line in cursor window
AP_a_page	db 6		;IX+16= maximum number of lines in cursor window
wind_adr	dw #4B00	;start of print address in the window
AP_item		dw #5555	;selected AP item
wind_curs_item	db #55		;current start cursor position of the window


;end of flags

core		db #55,#55,#55	

RX_buf		ds #80
TX_buf		ds 212	;worst case escaped SSID32 + password63 + syntax
buffers_len	equ $-RX_buf

	include "keyboard_and_print.asm"

bios_start		
	incbin "WifiBios21_NX.cod"
/*
;	IF element=0
	IFNDEF element
	incbin	"WifiBios19_MB.cod"
	ENDIF

;	IF element=1
	IFDEF element
	incbin	"WifiBios19_EL.cod"
	ENDIF
*/
bios_len	equ $-bios_start

terminal_code
	incbin "terminal11_next_setup.bin"
/*
;	IF element=1
	IFDEF element
	incbin	"uart03_el_for_wifi_setup.bin"
	ENDIF

;	IF element=0
	IFNDEF element
	incbin	"uart03_mb_for_wifi_setup.bin"
	ENDIF
;	incbin	"uart22f_hood.bin"	;terminal by Bill Gilberts
*/
terminal_len	equ $-terminal_code

systemky_code
systemky_len equ 0

	IFDEF standalone
total_len	equ $-start_ldir
	ELSE
;total_len	equ $-0-#C000 
total_len	equ $-start_mb_flash+strt_len-start_ldir	;40
	ENDIF