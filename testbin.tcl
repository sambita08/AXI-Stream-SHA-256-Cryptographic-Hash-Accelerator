with help of Tcl console, 4 test bin files with the corresponding content was created. 

set simdir "D:/VIVADO_PROJECTS/SHA_256/SHA_256.sim/sim_1/behav/xsim"
D:/VIVADO_PROJECTS/SHA_256/SHA_256.sim/sim_1/behav/xsim
file mkdir "$simdir/test_data"
set fp [open "$simdir/test_data/test1.bin" wb]
file195b8921e10
close $fp
set fp [open "$simdir/test_data/test2.bin" wb]
file195b8921610
puts -nonewline $fp "a"
close $fp
set fp [open "$simdir/test_data/test3.bin" wb]
file195b5e60660
puts -nonewline $fp "abc"
close $fp
set fp [open "$simdir/test_data/test4.bin" wb]
file195baac5850
puts -nonewline $fp "hello world"
close $fp
