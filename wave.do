onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_avalonmm_slave/clk_100
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_burstcount
add wave -noupdate /tb_avalonmm_slave/mem_byteenable
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_address
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_writedata
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_write
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_waitrequest
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_readdatavalid
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_readdata
add wave -noupdate -radix unsigned /tb_avalonmm_slave/mem_read
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {216509 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {430500 ps}
