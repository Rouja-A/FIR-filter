`timescale 1ns/1ns

module Array_mult_pipelined#(parameter WIDTH, parameter CONTROL_SIGNALS_WIDTH)
    ( input clk, rst,
    input[WIDTH-1:0] x, y,
    input[CONTROL_SIGNALS_WIDTH-1:0] ctrls_in,
    output[CONTROL_SIGNALS_WIDTH-1:0] ctrls_out,
    output[(2*WIDTH)-1:0] result);


    wire [WIDTH-1:0] x_in [0:WIDTH-1];
    wire [WIDTH-1:0] y_in [0:WIDTH-1];

    wire [WIDTH-2:0]input_cin[0:2*WIDTH-2];
    wire [WIDTH-2:0]output_cins[0:2*WIDTH-2];

    wire [(2*WIDTH)-1:0] results_in[0:2*WIDTH-2];
    wire [(2*WIDTH)-1:0] results_out[0:2*WIDTH-1];

    wire[CONTROL_SIGNALS_WIDTH-1:0] ctrl [0:2*WIDTH-1];
    
    genvar i;
    assign x_in[0] = x;
    assign y_in[0] = y;
    assign ctrl[0] = ctrls_in;
    assign output_cins[0] = 0;
    generate
        assign results_out[0][2*WIDTH-1] = 1'b0;

        for (i=0 ; i<2*WIDTH-1 ; i=i+1) begin: pipe
           PipeReg#(.WIDTH(2*WIDTH)) result_registers(.clk(clk), .rst(rst), .d_in(results_in[i]), .q_out(results_out[i+1]));
           PipeReg#(.WIDTH(CONTROL_SIGNALS_WIDTH)) control_registers(.clk(clk), .rst(rst), .d_in(ctrl[i]), .q_out(ctrl[i+1]));
        end: pipe

        for(i=0; i<WIDTH-1; i=i+1)begin: pipe2
            PipeReg#(.WIDTH(WIDTH)) x_inister(.clk(clk), .rst(rst), .d_in(x_in[i]), .q_out(x_in[i+1]));
            PipeReg#(.WIDTH(WIDTH)) y_inister(.clk(clk), .rst(rst), .d_in(y_in[i]), .q_out(y_in[i+1]));
        end: pipe2

        for(i=0 ; i<2*WIDTH-2; i=i+1)begin: carries
            PipeReg#(.WIDTH(WIDTH-1)) carry_inisters(.clk(clk), .rst(rst), .d_in(input_cin[i]), .q_out(output_cins[i+1]));
        end: carries

        for(i=WIDTH; i<2*WIDTH-1; i++)begin: xcalc
            assign results_out[0][i] = x_in[0][i-WIDTH+1] & y_in[0][WIDTH-1];
        end: xcalc

        for(i=0 ; i<WIDTH ; i=i+1)begin: ANDs
            assign results_out[0][i] = x_in[0][0] & y_in[0][i];
        end: ANDs

    endgenerate

    genvar j,k;
    generate
        assign results_in[WIDTH-1][2*WIDTH-1] = results_out[WIDTH-1][2*WIDTH-1];

        for(j=0; j<WIDTH-1; j=j+1)begin: res

            for(k=0; k<WIDTH-1; k=k+1)begin: fa
                Full_adder all(.a(x_in[j][j+1]&y_in[j][k]), .b(results_out[j][k+j+1]), .sum(results_in[j][k+j+1]), .cin(output_cins[j][k]), .cout(input_cin[j][k]));
            end: fa

            for(k=0; k<=j; k=k+1)begin: resin
                assign results_in[j][k] = results_out[j][k];
            end: resin

            for(k=WIDTH+j; k<2*WIDTH; k=k+1)begin: resin2
                assign results_in[j][k] = results_out[j][k];
            end: resin2

        end: res
        
        for(j=0; j<WIDTH-1; j=j+1)begin: famid
            Full_adder mid(.a(results_out[WIDTH-1][j+WIDTH]), .b(1'b0), .cin(output_cins[WIDTH-1][j]), .cout(input_cin[WIDTH-1][j]), .sum(results_in[WIDTH-1][WIDTH+j]));
        end: famid

        for(j=0; j<WIDTH; j=j+1)begin: res3
            assign results_in[WIDTH-1][j] = results_out[WIDTH-1][j]; 
        end: res3

        for(j=0; j<WIDTH-1; j=j+1)begin: fa_last
            for(k=0; k<WIDTH-1-j; k=k+1)begin: faline
                Full_adder last(.a(results_out[WIDTH+j][WIDTH+1+k+j]), .b(1'b0), .cin(output_cins[WIDTH+j][k]), .cout(input_cin[WIDTH+j][k]), .sum(results_in[WIDTH+j][WIDTH+1+k+j]));
            end: faline
            
            for(k=0; k<WIDTH+1+j; k=k+1)begin: res4
                assign results_in[WIDTH+j][k] = results_out[WIDTH+j][k];
            end: res4

        end: fa_last

    endgenerate

    assign ctrls_out = ctrl[2*WIDTH-1];
    assign result = results_out[2*WIDTH-1];
    
endmodule
