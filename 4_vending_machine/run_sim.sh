#!/bin/bash
# Run from the vending_machine directory
# Requires: Icarus Verilog (iverilog, vvp)

echo "Compiling testbench..."
iverilog -o sim/tb_fsm_controller.out \
    -I src \
    src/fsm_controller.v \
    sim/tb_fsm_controller.v

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

echo "Running simulation..."
cd sim
vvp tb_fsm_controller.out

echo ""
echo "VCD waveform file: sim/tb_fsm_controller.vcd"
echo "Open with VaporView or GTKWave to inspect signals."
