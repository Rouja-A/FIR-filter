`timescale 1ns/1ns

module Adder
    #(parameter INPUT_WIDTH = 16, parameter OUTPUT_WIDTH = 17)
    (input_1, input_2, out_put);
    input[INPUT_WIDTH-1:0] input_1;
    input[INPUT_WIDTH-1:0] input_2;
    output[OUTPUT_WIDTH-1:0] out_put;

    assign out_put = input_1 + input_2;

endmodule

module Full_adder(a, b, sum, cout, cin);
    input a, b, cin;
    output cout, sum;
    assign sum = a ^ b ^ cin;
    assign cout = ((a ^ b) & cin)|(a & b); 
endmodule