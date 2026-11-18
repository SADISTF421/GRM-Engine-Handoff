ENTRY(_start)
SECTIONS {
 . = 0x1000e180; .hook : { *(.hook) }
 . = 0x1000e186; .normal : { *(.normal) }
 . = 0x10029190; .guard : { *(.guard) }
 . = 0x1002a0bc; .iat : { *(.iat) }
 . = 0x11000000; .start : { *(.start) }
 . = 0x11001000; .data : { *(.data) }
}
