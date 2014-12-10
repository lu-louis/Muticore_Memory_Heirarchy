onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top_readmiss/plusclk
add wave -noupdate /tb_top_readmiss/rst
add wave -noupdate /tb_top_readmiss/addr_proc_0
add wave -noupdate /tb_top_readmiss/din_proc_0
add wave -noupdate /tb_top_readmiss/dout_proc_0
add wave -noupdate /tb_top_readmiss/u_top/proc_0/instruction
add wave -noupdate /tb_top_readmiss/u_top/proc_0/request
add wave -noupdate /tb_top_readmiss/u_top/proc_0/stall
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/controller/state
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/controller/sub_state
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/controller/bus_get
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/controller/bus_get_loader
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_active
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_grant
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_hold
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_req
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/bus_req_type
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/transmitter_input_sel
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/transmitter_addr_sel
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/proc_id
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/req_addr_v_reg
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/op_reg
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/request_va
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/pa_found
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/request_pa
add wave -noupdate /tb_top_readmiss/u_top/cache_L1_0/transmitter
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/rst
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/plusclk
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/req_1
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/req_2
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/req_3
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/request_array
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/grant_1
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/grant_2
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/grant_3
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/grant_array
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/hold_1
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/hold_2
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/hold_3
add wave -noupdate /tb_top_readmiss/u_top/arbiter_bus1_0/hold_array
add wave -noupdate -expand /tb_top_readmiss/u_top/bus_0
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {71 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 352
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ns} {105 ns}
