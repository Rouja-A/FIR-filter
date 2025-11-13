`timescale 1ns/1ns

module FIRfilter #(parameter WIDTH = 16, parameter LENGHT = 100) (clk, rst, input_valid, FIR_input, output_valid, ready_for_input, FIR_output);

   localparam OUTPUT_WIDTH = $clog2(LENGHT) + 2*WIDTH;
   input clk, rst, input_valid;
   input [WIDTH-1:0] FIR_input;
   output output_valid, ready_for_input;
   output[OUTPUT_WIDTH-1:0] FIR_output;

   wire load_input, clr_input, clr_counter, inc_counter, counter_co, load_result, clr_result, output_valid_interconnect;

   DP #(.WIDTH(WIDTH), .LENGHT(LENGHT)) datapath
                (.clk(clk), .rst(rst), .operand_in(FIR_input),
                 .result(FIR_output), .load_input(load_input), .clr_input(clr_input),
                 .clr_counter(clr_counter), .inc_counter(inc_counter), .counter_co(counter_co),
                  .output_valid(output_valid_interconnect), .load_result(load_result), .clr_result(clr_result), .output_valid_out(output_valid));

   CTRL controller (.clk(clk), .rst(rst), .input_valid(input_valid), .output_valid(output_valid_interconnect),
                      .clr_input(clr_input), .load_input(load_input), .counter_co(counter_co), .clr_counter(clr_counter), 
                      .inc_counter(inc_counter), .load_result(load_result), .clr_result(clr_result), .ready_for_input(ready_for_input));
endmodule
