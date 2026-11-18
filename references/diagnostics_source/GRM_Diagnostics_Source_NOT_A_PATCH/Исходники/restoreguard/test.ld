ENTRY(_start)
SECTIONS {
 . = 0x08048000; .text : { *(.text) } .data : { *(.data) }
 . = 0x101f27a0; .normal : { *(.normal) }
 . = 0x101f2859; .mismatch : { *(.mismatch) }
 . = 0x1061f270; .hook : { *(.hook) }
}
