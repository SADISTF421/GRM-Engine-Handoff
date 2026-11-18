SECTIONS {
 . = 0x10029190; .patch : { *(.patch) }
 here_rva = here - 0x10000000;
 normal = 0x1000e186;
}
