//------------------------------------------------------------------------------
// Testbench for noise_estimation module
//------------------------------------------------------------------------------
//`include "/users/eplkls/Project/design/noise_estimation_FSM.sv"
//`include "/users/eplkls/Project/design/mean_unit.sv"
//`include "/users/eplkls/Project/design/shift_register.sv"
//`include "/users/eplkls/Project/design/variance_unit.sv"


module noise_estimation_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter TOTAL_SAMPLES = 4;

    // Testbench signals
    logic                   clk;
    logic                   rst_n;
    logic                   start_of_frame;
    logic                   end_of_frame;
    logic [DATA_WIDTH-1:0]  data_in;
    logic                   start_data;
	logic [31:0]            blocks_per_frame;

    logic [2*DATA_WIDTH-1:0] estimated_noise;
    logic                   estimated_noise_ready;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // DUT instantiation
    noise_estimation #(
        .DATA_WIDTH(DATA_WIDTH),
        .TOTAL_SAMPLES(TOTAL_SAMPLES)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_of_frame(start_of_frame),
        .end_of_frame(end_of_frame),
        .data_in(data_in),
        .start_data(start_data),
		.blocks_per_frame(blocks_per_frame),
        .estimated_noise(estimated_noise),
        .estimated_noise_ready(estimated_noise_ready)
    );


	reg [31:0] count = 1;

	task send_block(input first_block);
         #20;// repeat (2) @(posedge clk) // the delta between blocks. minimum is 1
        if (first_block) begin
            start_of_frame = 1;
		end
		if (!first_block) begin
			#20;
		end
		start_data = 1;
        // Feed data for the first block
        repeat (TOTAL_SAMPLES) begin

			#5; //@(negedge clk) 
			data_in = data_in + 4; // changed to have bigger variances [05.12.24]
			count = count + 1;
			if (data_in==1) begin
				//#10;
			end
			#5; //@(posedge clk)
			start_data = 0;
			start_of_frame = 0;         
		end
	endtask

    // Test vectors and stimulus

    initial begin
        // Initialize signals
        rst_n = 0;
        start_of_frame = 0;
        end_of_frame = 0;
        data_in = 0;
        start_data = 0;
		blocks_per_frame = 4;
        // Reset sequence
        #25 rst_n = 1;

        // Send blocks
        for(int i = 1; i <= blocks_per_frame; i++) begin
			if(i==blocks_per_frame) begin
				end_of_frame = 1;
			end else begin
				end_of_frame = 0;
			end
            send_block(i == 1);            
        end
		end_of_frame = 0;
        // Wait for estimated noise to be ready
        //wait (estimated_noise_ready);
        $display("Estimated noise: %0d", estimated_noise);

        // Finish simulation
        #100;
        $finish;
    end

endmodule
