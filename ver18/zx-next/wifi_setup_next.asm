 DEVICE ZXSPECTRUM128
 DEFINE standalone
 DEFINE ZXNEXT
 MODULE v0
 INCLUDE "wifi_setup_main.asm"
 ASSERT total_len < 16384
 SAVEBIN "wifi_setup_next18.bin",start_address,total_len
 ENT
 ORG #6000
next_loader
 DB 0,10
 DW next_line_end-next_line
next_line
 DB #FD,#B0,34,"27647",34,58,#EF,34,34,#AF,58,#F9,#C0,#B0,34,"49152",34,13
next_line_end
 EMPTYTAP "wifi_setup_next18.tap"
 SAVETAP "wifi_setup_next18.tap",BASIC,"WiFi NX18",next_loader,next_line_end-next_loader,10
 SAVETAP "wifi_setup_next18.tap",CODE,"WiFi NX18",start_address,total_len
 ENDMODULE