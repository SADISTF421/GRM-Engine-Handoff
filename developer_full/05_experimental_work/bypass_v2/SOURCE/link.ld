SECTIONS {
 . = 0x1061fa00; .patch : { *(.patch) }
 normal = 0x100735a5;
 skip = 0x100735cd;
}
