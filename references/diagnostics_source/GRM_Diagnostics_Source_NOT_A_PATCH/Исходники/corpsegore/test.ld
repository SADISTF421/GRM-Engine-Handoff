ENTRY(_start)
SECTIONS {
 . = 0x08048000; .text : { /data/grm/corpsegore/test.o(.text) } .data : { *(.data) }
 . = 0x10013b38; .prealive : { *(.prealive) }
 . = 0x10013b76; .predead : { *(.predead) }
 . = 0x10013bd9; .postalive : { *(.postalive) }
 . = 0x10013d4a; .exit : { *(.exit) }
 . = 0x10120074; .siggo : { *(.siggo) }
 . = 0x10120096; .sigexit : { *(.sigexit) }
 . = 0x10467fdc; .constzero : { *(.constzero) }
 . = 0x1061fc00; .hook : { /data/grm/corpsegore/hook.o(.text) }
}
