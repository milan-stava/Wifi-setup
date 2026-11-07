	DEVICE ZXSPECTRUM128

	DEFINE standalone
	MODULE v0
	INCLUDE "wifi_setup_main.asm"
	ASSERT total_len < 16384
	SAVEBIN "wifi_setup_standalone18",start_address,total_len
	; BASIC: 10 CLEAR VAL "27647": LOAD "" CODE: RANDOMIZE USR VAL "49152"
	; Keep the BASIC stack below the terminal destination at 30000.
	ENT	;end application DISP before emitting the BASIC loader
	ORG #6000
tap_loader
	DB 0,10
	DW tap_line_end-tap_line
tap_line
	DB #FD,#B0,34,"27647",34,58,#EF,34,34,#AF,58,#F9,#C0,#B0,34,"49152",34,13
tap_line_end
	EMPTYTAP "wifi_setup_standalone18.tap"
	SAVETAP "wifi_setup_standalone18.tap",BASIC,"WiFi 18",tap_loader,tap_line_end-tap_loader,10
	SAVETAP "wifi_setup_standalone18.tap",CODE,"WiFi 18",start_address,total_len
	ENDMODULE
	UNDEFINE standalone




