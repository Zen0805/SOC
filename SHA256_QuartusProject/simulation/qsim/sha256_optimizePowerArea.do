onerror {quit -f}
vlib work
vlog -work work sha256_optimizePowerArea.vo
vlog -work work sha256_optimizePowerArea.vt
vsim -novopt -c -t 1ps -L cycloneii_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.sha256_optimizePowerArea_vlg_vec_tst
vcd file -direction sha256_optimizePowerArea.msim.vcd
vcd add -internal sha256_optimizePowerArea_vlg_vec_tst/*
vcd add -internal sha256_optimizePowerArea_vlg_vec_tst/i1/*
add wave /*
run -all
