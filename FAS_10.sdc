# operating conditions and boundary conditions #

set cycle  10         ;	#clock period defined by designer

create_clock -period $cycle [get_ports  clk]
set_dont_touch_network      [get_clocks clk]
set_clock_uncertainty  1  [get_clocks clk]
set_clock_latency      1  [get_clocks clk]

set_input_delay 1 -clock clk [get_ports rst]

set_output_delay 1 -clock clk [get_ports done]

set_fix_hold clk

set_load -pin_load 1  [all_outputs]
set_drive          1  [all_inputs]

set_operating_conditions -min_library fast -min fast -max_library slow -max slow
set_wire_load_model -name tsmc13_wl10 -library slow  

# set_operating_conditions -library N16ADFP_StdCellff0p88v125c_ccs
# set_wire_load_model -name ZeroWireload -library N16ADFP_StdCellff0p88v125c_ccs