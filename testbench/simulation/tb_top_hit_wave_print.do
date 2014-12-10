restart -f -nowave

add wave -divider Interface
add wave -noupdate /tb_top_hit/plusclk
add wave -noupdate /tb_top_hit/rst
add wave -noupdate /tb_top_hit/addr_proc_0
add wave -noupdate /tb_top_hit/din_proc_0
add wave -noupdate /tb_top_hit/dout_proc_0
add wave -divider Processor
add wave -noupdate /tb_top_hit/plusclk
add wave -noupdate /tb_top_hit/u_top/proc_0/instruction
add wave -noupdate /tb_top_hit/u_top/proc_0/request
add wave -noupdate /tb_top_hit/u_top/proc_0/stall
add wave -noupdate /tb_top_hit/u_top/proc_0/cache_hit
add wave -divider L1Cache
add wave -noupdate /tb_top_hit/plusclk
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/inst_loader
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/controller/halt
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/controller/hit
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/controller/we_data_vector
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/controller/we_flag_vector
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/offset_reg
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/new_data_reg
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/data_sel_offset
add wave -noupdate /tb_top_hit/u_top/cache_L1_0/data_block_0/data

run
view wave
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {79 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 327
configure wave -valuecolwidth 100
configure wave -justifyvalue left
#configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
-signalnamewidth [2] 
update
WaveRestoreZoom {0 ns} {105 ns}
