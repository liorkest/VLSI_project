#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo '''Usage:
		width
		height'''
    exit 1
fi

# Assign arguments to variables
WIDTH=$1
HEIGHT=$2


# Define array of images
image_files=("images_tb/cat_dog_noisy.bmp" "images_tb/fish_noisy.bmp" "images_tb/ferrari_noisy.bmp" "images_tb/turtle_noisy.bmp")

for i in {0..3}; do
    echo "Processing file: ${image_files[i]}"
    # Call the Python script
    # output files format : image0_noisy_in.hex
    INPUT_HEX="image${i}_noisy_in.hex"
	python convert_bmp_to_hex.py "${image_files[i]}" $INPUT_HEX 2>error.log
	# Check the exit status of the Python script
	if [ $? -ne 0 ]; then
	    echo "ERROR: Python script failed. Details:"
 	   cat error.log
 	   exit 1
	fi
done


# compile & run verilog
vcs -kdb -sverilog -debug_access+all -full64 memory_writer.sv AXI_stream_slave.sv AXI_memory_slave3channels.sv memory_reader_noise_estimation.sv AXI_memory_master_burst.sv RGB_mean.sv DW_div.v DW_div_10bit_inst.sv shift_register.sv mean_unit.sv variance_unit.sv noise_estimation_FSM.sv noise_estimation_top.sv wiener_block_stats.sv wiener_calc.sv wiener_block_stats_FSM.sv wiener_1_channel.sv wiener_3_channels.sv DW_div_32bit_inst.sv memory_reader_wiener.sv TOP_AXI_stream_memory_noise_estimation_wiener_NO_AXI_mem_slave.sv multiple_images_filtering_tb.sv -pvalue+TOP_FULL_image_filtering.WIDTH=$WIDTH -pvalue+TOP_FULL_image_filtering_tb.HEIGHT=$HEIGHT 

simv     # simulation

# process output files and convert to bmp images
for i in {0..3}; do
    echo "Processing file: ${image_files[i]}"
    # Call the Python script
    	OUTPUT_HEX=image${i}_noisy_out.hex
	OUTPUT_REORDER_HEX=image${i}_noisy_out_reordered.hex
	OUTPUT_BMP=image${i}_noisy_out.bmp
	# reorder HEX
	python reorder_hex_data.py $OUTPUT_HEX $OUTPUT_REORDER_HEX $WIDTH
	# Check if the script executed successfully
	if [ $? -eq 0 ]; then
	    echo "Conversion completed successfully. Output saved to $OUTPUT_REORDER_HEX."
	else
	    echo "An error occurred during the conversion."
	    exit 1
	fi
	# convert output from hex to bmp
	python convert_hex_to_bmp.py $OUTPUT_REORDER_HEX $OUTPUT_BMP $WIDTH $HEIGHT

	# Check if the script executed successfully
	if [ $? -eq 0 ]; then
	    echo "Conversion completed successfully. Output saved to $OUTPUT_BMP."
	else
	    echo "An error occurred during the conversion."
	    exit 1
	fi
done


