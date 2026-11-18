ENTRY(_start)
SECTIONS {
 . = 0x08048000; .text : { *(.text) } .data : { *(.data) }
 . = 0x10146f16; .fallback : { *(.fallback) }
 . = 0x10466788; .iata : { *(.iata) }
 . = 0x10466aa0; .iatb : { *(.iatb) }
 . = 0x10466d74; .iatmsg : { *(.iatmsg) }
 . = 0x10484334; .vt : { *(.vt) }
 . = 0x1061f400; .hook : { *(.hook) }
}
