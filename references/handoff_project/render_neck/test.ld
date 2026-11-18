ENTRY(_start)
SECTIONS {
 . = 0x45abd0; .lookup : { *(.lookup) }
 . = 0x467514; .sitex : { *(.sitex) }
 . = 0x4675ce; .sitey : { *(.sitey) }
 . = 0x467688; .sitez : { *(.sitez) }
 . = 0x56d000; .patch : { stub.o(.text) }
 . = 0x570000; .main : { *(.main) }
 . = 0x571000; .data : { *(.data) }
 /DISCARD/ : { *(.comment) *(.note*) }
}
