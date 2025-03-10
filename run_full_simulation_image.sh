#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo '''Usage: input_bmp_file
		width
		height'''
    exit 1
fi

# Assign arguments to variables
INPUT_BMP=$1
WIDTH=$2
HEIGHT=$3
filename=$(basename $INPUT_BMP .bmp)
INPUT_HEX=hex_data_in.hex
OUTPUT_HEX=hex_data_out.hex
OUTPUT_REORDER_HEX=${filename}_out.hex
OUTPUT_BMP=${filename}_out.bmp

# Call the Python script
python convert_bmp_to_hex.py "$INPUT_BMP" "$INPUT_HEX" 2>error.log
# Check the exit status of the Python script
if [ $? -ne 0 ]; then
    echo "ERROR: Python script failed. Details:"
    cat error.log
    exit 1
fi
# compile & run verilog
vcs -timescale=1ns/1ps -kdb -sverilog -debug_access+all -full64 memory_writer.sv AXI_stream_slave.sv AXI_memory_slave3channels.sv memory_reader_noise_estimation.sv AXI_memory_master_burst.sv RGB_mean.sv DW_div.v DW_div_10bit_inst.sv shift_register.sv mean_unit.sv variance_unit.sv noise_estimation_FSM.sv noise_estimation_top.sv wiener_block_stats.sv wiener_calc.sv wiener_block_stats_FSM.sv wiener_1_channel.sv wiener_3_channels.sv DW_div_32bit_inst.sv memory_reader_wiener.sv TOP_AXI_stream_memory_noise_estimation_wiener_NO_AXI_mem_slave.sv TOP_FULL_image_filtering_tb.sv -pvalue+TOP_FULL_image_filtering.WIDTH=$WIDTH -pvalue+TOP_FULL_image_filtering_tb.HEIGHT=$HEIGHT 

simv     # simulation
# reorder HEX
python reorder_hex_data.py $OUTPUT_HEX $OUTPUT_REORDER_HEX $WIDTH
# Check if the script executed successfully
if [ $? -eq 0 ]; then
    echo "Hex reorder completed successfully. Output saved to  $OUTPUT_REORDER_HEX."
else
    echo "An error occurred during the conversion."
    exit 1
fi
# convert output from hex to bmp
python convert_hex_to_bmp.py $OUTPUT_REORDER_HEX $OUTPUT_BMP $WIDTH $HEIGHT

# Check if the script executed successfully
if [ $? -eq 0 ]; then
    echo "bmp Conversion completed successfully. Output saved to $OUTPUT_BMP."
else
    echo "An error occurred during the conversion."
    exit 1
fi

