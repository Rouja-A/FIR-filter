`timescale 1ns/1ns

module Reg#(parameter WIDTH)
        (input [WIDTH-1:0] d_in,
        input clk, rst, load, clear,
        output reg[WIDTH-1:0] q_out);

        always @(posedge clk, posedge rst) begin
            if(rst) begin
                q_out <= 0; 
            end
            else if(clear) begin
                    q_out <= 0;
            end
            else if(load) begin
                    q_out <= d_in;
            end
        end

endmodule
