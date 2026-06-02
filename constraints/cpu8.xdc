## ============================================================
##  Constraints for Digilent Basys3 (XC7A35T)
##  Adapt pin names for other Artix-7 / Nexys boards
## ============================================================

## ---- System Clock (100 MHz) ----
set_property PACKAGE_PIN W5    [get_ports clk]
set_property IOSTANDARD  LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports clk]

## ---- Reset button (active high, mapped to BTNC) ----
set_property PACKAGE_PIN U18   [get_ports rst]
set_property IOSTANDARD  LVCMOS33 [get_ports rst]

## ---- Halted LED (LD0) ----
set_property PACKAGE_PIN U16   [get_ports halted]
set_property IOSTANDARD  LVCMOS33 [get_ports halted]

## ---- Debug: PC on LEDs LD7..LD0 (8 bits) ----
set_property PACKAGE_PIN U16   [get_ports {dbg_pc[0]}]
set_property PACKAGE_PIN E19   [get_ports {dbg_pc[1]}]
set_property PACKAGE_PIN U19   [get_ports {dbg_pc[2]}]
set_property PACKAGE_PIN V19   [get_ports {dbg_pc[3]}]
set_property PACKAGE_PIN W18   [get_ports {dbg_pc[4]}]
set_property PACKAGE_PIN U15   [get_ports {dbg_pc[5]}]
set_property PACKAGE_PIN U14   [get_ports {dbg_pc[6]}]
set_property PACKAGE_PIN V14   [get_ports {dbg_pc[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {dbg_pc[*]}]

## ---- Debug: Flags on 4 LEDs ----
set_property PACKAGE_PIN V13   [get_ports {dbg_flags[0]}]
set_property PACKAGE_PIN V3    [get_ports {dbg_flags[1]}]
set_property PACKAGE_PIN W3    [get_ports {dbg_flags[2]}]
set_property PACKAGE_PIN U3    [get_ports {dbg_flags[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_flags[*]}]

## ---- State on 3 LEDs ----
set_property PACKAGE_PIN P3    [get_ports {dbg_state[0]}]
set_property PACKAGE_PIN N3    [get_ports {dbg_state[1]}]
set_property PACKAGE_PIN P1    [get_ports {dbg_state[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dbg_state[*]}]

## ---- Timing constraints ----
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
