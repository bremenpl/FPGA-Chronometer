
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name chronometer -dir "E:/Dropbox/programowanie/FPGA projects/proj1counter/planAhead_run_2" -part xc3s100ecp132-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "chronometer.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {chronometer.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top chronometer $srcset
add_files [list {chronometer.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s100ecp132-4
