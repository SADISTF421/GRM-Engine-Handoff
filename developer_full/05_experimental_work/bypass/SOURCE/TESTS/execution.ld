ENTRY(_start)
SECTIONS {
 . = 0x100735a0; .hook : { *(.hook) }
 . = 0x100735a5; .normal : { *(.normal) }
 . = 0x100735cd; .skip : { *(.skip) }
 . = 0x1061f940; .cave : { *(.cave) }
 . = 0x11000000; .start : { *(.start) }
 . = 0x11001000; .data : { *(.data) }
}
