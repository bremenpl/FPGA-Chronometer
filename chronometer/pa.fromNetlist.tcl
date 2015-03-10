
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name chronometer -dir "E:/Dropbox/programowanie/FPGA projects/proj1counter/planAhead_run_1" -part xc3s100ecp132-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/Dropbox/programowanie/FPGA projects/chronometer/proj1counter.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/Dropbox/programowanie/FPGA projects/chronometer} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "chronometer.ucf" [current_fileset -constrset]
add_files [list {chronometer.ucf}] -fileset [get_property constrset [current_run]]
link_design
