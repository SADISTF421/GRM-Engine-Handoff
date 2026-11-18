ENTRY(_start)
SECTIONS {
 . = 0x08048000; .text : { /data/grm/ogsrpose/test.o(.text) } .data : { *(.data) }
 . = 0x101f22c3; .earlyret : { *(.earlyret) }
 . = 0x101f22e4; .lateret : { *(.lateret) }
 . = 0x1046678c; .iatset : { *(.iatset) }
 . = 0x10466aa0; .iatbone : { *(.iatbone) }
 . = 0x10466d74; .iatmsg : { *(.iatmsg) }
 . = 0x1061f800; .hook : { /data/grm/ogsrpose/hook.o(.text) }
}
