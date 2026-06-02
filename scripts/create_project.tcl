# ============================================================
#  create_project.tcl
#  Run this in Vivado Tcl Console to build the project:
#    source create_project.tcl
# ============================================================

set project_name "cpu8"
set project_dir  [pwd]
set part         "xc7a35tcpg236-1"   ;# Basys3 — change for your board

# Create project
create_project $project_name $project_dir/$project_name -part $part

# Add sources
add_files -norecurse [list \
    cpu8_defs.vh \
    alu.v        \
    register_file.v \
    memory.v     \
    cpu8.v       \
]

# Add testbench (simulation only)
add_files -fileset sim_1 -norecurse cpu8_tb.v

# Add constraints
add_files -fileset constrs_1 -norecurse cpu8.xdc

# Set top module
set_property top cpu8 [current_fileset]
set_property top cpu8_tb [get_filesets sim_1]

# Include path for `include
set_property include_dirs [list [get_property directory [current_project]]] \
    [current_fileset]
set_property include_dirs [list [get_property directory [current_project]]] \
    [get_filesets sim_1]

puts "Project created. Use Flow > Run Simulation to simulate,"
puts "or Flow > Run Implementation > Generate Bitstream to synthesize."
