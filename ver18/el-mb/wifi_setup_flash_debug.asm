	DEVICE ZXSPECTRUM128

	DEFINE machine
;	DEFINE element 
;	DEFINE standalone
	MODULE v0
	INCLUDE "wifi_setup_main.asm"
	ASSERT total_len < 16384
	SAVEBIN "wifi_setup_flash18_debug",0,total_len
	ENDMODULE
;	UNDEFINE standalone
;	UNDEFINE element
;	UNDEFINE machine
;	LABELSLIST "navesti_elbsd"



