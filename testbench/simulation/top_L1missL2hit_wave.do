restart -f -nowave

onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider Interface
add wave -noupdate /tb_top_readmiss/plusclk
#add wave -noupdate /tb_top_readmiss/rst
add wave -noupdate /tb_top_readmiss/addr_proc_0
#add wave -noupdate /tb_top_readmiss/din_proc_0
add wave -noupdate /tb_top_readmiss/dout_proc_0

add wave -noupdate -divider Processor_0
add wave -noupdate /tb_top_readmiss/plusclk
add wave -noupdate /tb_top_readmiss/u_top/proc_0/cache_hit
add wave -noupdate /tb_top_readmiss/u_top/proc_0/instruction
add wave -noupdate /tb_top_readmiss/u_top/proc_0/request
add wave -noupdate /tb_top_readmiss/u_top/proc_0/stall

add wave -noupdate -divider Cache_L1a
add wave -noupdate /tb_top_readmiss/plusclk
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/inst_loader
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/controller/state
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/controller/sub_state
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/dout_proc
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/data_sel_offset
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/receiver_buf_0
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_active
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_direction
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_grant
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_hold
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_req
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_req_type
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/get_reply
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/write_enable_flag
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/write_enable_addr
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/write_enable_data
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/data_din_sel
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/offset_reg
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/din_proc_loader
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/new_data_reg
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/new_addr_tag
#add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/new_addr_p
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/transmitter
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/receiver_0

add wave -noupdate -divider bus_0_a
add wave -noupdate -expand /tb_top_readmiss/u_top/bus_0

add wave -noupdate -divider arbiter_0_a
#add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/plusclk
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/bus_active
#add wave -noupdate -expand /tb_top_readmiss/u_top/arbiter_bus_0_a/request_array
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/req_1
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/req_3
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/hold_1
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/hold_3
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/grant_1
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus_0_a/grant_3

add wave -noupdate -divider Cache_L2a
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/plusclk
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/controller/state
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/controller/sub_state
add wave -noupdate -expand /tb_top_readmiss/u_top/cache_L2_0/bus_direction
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/receiver_0
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/transmitter_0
#add wave -noupdate -expand /tb_top_readmiss/u_top/cache_L2_0/ready_reg
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/processing_info_reg
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/processing_data_reg
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/next_data
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/data_output_sel
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/processing_index
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/req_valid_flag
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/hit
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/queue_write_enable

add wave -noupdate -divider Cache_L2a_controller+queue
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/controller/queue_empty
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/controller/pop_queue
add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/controller/pwb_addr_match

#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/queue_table
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/rst
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/wr_index
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/empty
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/counter
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/pop_en
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/task_queue/push_en
#add wave -noupdate /tb_top_readmiss/u_top/cache_L2_0/tag_block/tag_table

run -all

TreeUpdate [SetDefaultTree]
#WaveRestoreCursors {{Cursor 1} {47 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 378
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
#WaveRestoreZoom {0 ns} {105 ns}
