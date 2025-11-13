`timescale 1ns/1ns

module Signed_multiplier#(parameter WIDTH=16, parameter CONTROL_SIGNALS_WIDTH =3) (x, y, result, clk, rst, ctrls_in, ctrls_out);
    input clk, rst;
    input[WIDTH-1:0] x, y;
    input[CONTROL_SIGNALS_WIDTH-1:0] ctrls_in;
    output[CONTROL_SIGNALS_WIDTH-1:0] ctrls_out;
    output[(2*WIDTH)-1:0] result;

    wire[2*WIDTH-1:0] x_sign, y_sign;
    assign x_sign = {{WIDTH{x[WIDTH-1]}}, x};
    assign y_sign = {{WIDTH{y[WIDTH-1]}}, y};

    wire[4*WIDTH-1:0] result_extended;
    
    Array_mult_pipelined#(.WIDTH(2*WIDTH), .CONTROL_SIGNALS_WIDTH(CONTROL_SIGNALS_WIDTH)) mult
     (.clk(clk), 
    .rst(rst),
    .x(x_sign),
    .y(y_sign),
    .result(result_extended), 
    .ctrls_in(ctrls_in), 
    .ctrls_out(ctrls_out));
    assign result = result_extended[2*WIDTH-1:0];

endmodule
