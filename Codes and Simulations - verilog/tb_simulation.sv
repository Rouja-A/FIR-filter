`timescale 1ns/1ps

module tb_FIRfilter();
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg data_valid_in, data_valid_out, data_ready_in;
    reg [15:0] data_in = 16'd0;
    wire [37:0] data_out;

    // Instantiate the DUT
    FIRfilter #(.WIDTH(16), .LENGHT(64)) uut (
        .clk(clk),
        .rst(~rst_n),
        .FIR_input(data_in),
        .input_valid(data_valid_in),
        .FIR_output(data_out),
        .output_valid(data_valid_out),
        .ready_for_input(data_ready_in)
    );

    // Test vectors and reference outputs
    reg [15:0] test_inputs [0:221183];
    reg [37:0] golden_outputs [0:221183];
    integer outfile;

    // Clock generation
    always #5 clk = ~clk;

    // Read test data
    initial begin
        $readmemb("inputs.txt", test_inputs);
        $readmemb("outputs.txt", golden_outputs);
    end

    // Test sequence
    initial begin
        outfile = $fopen("sim_results.txt");
        $display("=== FIR Filter Simulation Started ===");

        // rst sequence
        rst_n = 1'b0;
        data_valid_in = 1'b0;
        #20 rst_n = 1'b1;
        $display("rst released, beginning stimulus...");

        for (int j = 0; j < 221183; j++) begin
            // Apply input sample
            #30 data_in = test_inputs[j];
                data_valid_in = 1'b1;
            #10 data_valid_in = 1'b0;

            // Wait for output
            @(posedge data_valid_out);
            $fwrite(outfile, "%b\n", data_out);

            // Compare with expected
            if (data_out !== golden_outputs[j]) begin
                $display("MISMATCH at sample %0d: got %b, expected %b", j, data_out, golden_outputs[j]);
            end else begin
                $display("PASS sample %0d: output %b matches expected %b", j, data_out, golden_outputs[j]);
            end
        end

        $fclose(outfile);
        $display("=== Simulation Completed ===");
        #50 $finish;
    end

endmodule

