`timescale 1ns/1ns

module CTRL
    (input clk, rst, input_valid, counter_co,
    output reg clr_input, load_input, clr_result, load_result, clr_counter, inc_counter, output_valid, ready_for_input);

    parameter INIT = 3'b000;
    parameter DELAY = 3'b001;
    parameter LOAD = 3'b010;
    parameter COMPUTE = 3'b011;
    parameter DONE = 3'b100;

    reg[2:0] present_state, next_state;

    always@(posedge clk, posedge rst)begin
        if(rst)begin
            present_state <= INIT;
        end
        else begin
            present_state <= next_state;
        end
    end

    always@(present_state, input_valid, counter_co)begin
        case(present_state)
            INIT: next_state <= DELAY;
            DELAY: next_state <= input_valid ? LOAD : DELAY;
            LOAD: next_state <= COMPUTE;
            COMPUTE: next_state <= counter_co ? DONE : COMPUTE;
            DONE: next_state <= DELAY;
            default: next_state <= INIT;
        endcase
    end

    always@(present_state)begin
        {clr_input, load_input, clr_result, load_result, clr_counter, inc_counter, output_valid, ready_for_input} = 8'b0;
        case(present_state)
            INIT: {clr_counter, clr_result, clr_input} = 3'b111;
            DELAY: {clr_result, ready_for_input} = 2'b11;
            LOAD: load_input = 1'b1;
            COMPUTE: {load_result, inc_counter} = 2'b11;
            DONE: {clr_counter, output_valid} = 2'b11;
            default: {clr_input, load_input, clr_result, load_result, clr_counter, inc_counter, output_valid, ready_for_input} = 8'b0;
        endcase
    end
endmodule
