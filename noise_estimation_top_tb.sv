//------------------------------------------------------------------------------
// Testbench for noise_estimation module
//------------------------------------------------------------------------------

int count=1; // for signal generation

module noise_estimation_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter TOTAL_SAMPLES = 4;
    parameter BLOCKS_PER_FRAME = 4;

    // Testbench signals
    logic                   clk;
    logic                   rst_n;
    logic                   start_of_frame;
    logic                   end_of_frame;
    logic [DATA_WIDTH-1:0]  data_in;
    logic                   start_data;
    logic                   end_data;

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
        .TOTAL_SAMPLES(TOTAL_SAMPLES),
        .BLOCKS_PER_FRAME(BLOCKS_PER_FRAME)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start_of_frame(start_of_frame),
        .end_of_frame(end_of_frame),
        .data_in(data_in),
        .start_data(start_data),
        .end_data(end_data),
        .estimated_noise(estimated_noise),
        .estimated_noise_ready(estimated_noise_ready)
    );


	task send_block(input first_block);
        @(posedge clk);
        start_data = 1;
        if (first_block) begin
            start_of_frame = 1;
        end
        @(posedge clk);
        start_data = 0;
        start_of_frame = 0;
        // Feed data for the first block
        repeat (TOTAL_SAMPLES) begin
            @(posedge clk);
            data_in = count % (2**DATA_WIDTH);
            count = count + 1;
        end
        @(posedge clk);
        end_data = 1;
        @(posedge clk);
        end_data = 0;
	endtask

    // Test vectors and stimulus
    int count = 1;
    initial begin
        // Initialize signals
        rst_n = 0;
        start_of_frame = 0;
        end_of_frame = 0;
        data_in = 0;
        start_data = 0;
        end_data = 0;

        // Reset sequence
        #20 rst_n = 1;

        // Send blocks
        for(int i = 1; i <= BLOCKS_PER_FRAME; i++) begin
            send_block(i == 1);
            // set for next cycle
            if(i==BLOCKS_PER_FRAME - 1) begin
                end_of_frame = 1;
            end else begin
                end_of_frame = 0;
            end
        end

        // Wait for estimated noise to be ready
        wait (estimated_noise_ready);
        $display("Estimated noise: %0d", estimated_noise);

        // Finish simulation
        #100;
        $finish;
    end

endmodule
