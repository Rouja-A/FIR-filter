`timescale 1ns/1ns
module PipeReg #(
    parameter WIDTH = 16
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] d_in,
    output reg  [WIDTH-1:0] q_out
);

    always @(posedge clk, posedge rst) begin
        if (rst)
            q_out <= '0;
        else
            q_out <= d_in;
    end

endmodule

