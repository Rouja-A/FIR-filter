`timescale 1ns/1ns

module test_assertion();

    reg clk = 1'b0, reset = 1'b0, input_valid = 1'b0;
    reg [15:0] FIR_input = 0;
    wire [37:0] FIR_output;
    wire output_valid, ready_for_input;

    
    FIR_filter #(.WIDTH(16), .LENGHT(64)) filter (
        .clk(clk),
        .reset(reset),
        .FIR_input(FIR_input),
        .input_valid(input_valid),
        .FIR_output(FIR_output),
        .output_valid(output_valid),
        .ready_for_input(ready_for_input)
    );

    reg [15:0] inputs [0:221183];
    reg [37:0] expected_values [0:221183];
    integer i;

    localparam PIPELINE_DEPTH = 64
    reg [31:0] input_pipeline [0:PIPELINE_DEPTH-1];
    integer k;

    always @(posedge clk) begin
        input_pipeline[0] <= input_valid ? i : input_pipeline[0];
        for (k = 1; k < PIPELINE_DEPTH; k = k + 1) begin
            input_pipeline[k] <= input_pipeline[k-1];
        end
    end

    always #10 clk = ~clk;

    initial begin
        $readmemb("inputs.txt", inputs);
        $readmemb("outputs.txt", expected_values);
    end


    // 1. Loading -> Calculation
    Loading: assert property (@(posedge clk) filter.load_input |=> filter.load_result) begin
        $display("[%0t] PASS: Transitioned from LOADING to CALCULATION", $time);
    end else begin
        $display("[%0t] FAIL: Did not transition from LOADING to CALCULATION", $time);
    end

    // 2. Counter assertion
    counter: assert property (@(posedge clk) filter.load_input |-> ##5 filter.counter_co) begin
        $display("[%0t] PASS: Counter asserted correctly 5 cycles after load_input", $time);
    end else begin
        $display("[%0t] FAIL: Counter not asserted 5 cycles after load_input", $time);
    end

    // 3. Clear result after calculation
    Clear_result: assert property (@(posedge clk) filter.output_valid_interconnect |=> 
                                   (filter.ready_for_input && filter.clr_result)) begin
        $display("[%0t] PASS: Calculation completed, ready for new input", $time);
    end else begin
        $display("[%0t] FAIL: Module not ready for new input after calculation", $time);
    end

    // 4. Pipeline latency check
    output_valid_pipeline: assert property (@(posedge clk) filter.output_valid_interconnect |-> ##PIPELINE_DEPTH output_valid) begin
        $display("[%0t] PASS: Pipeline latency as expected", $time);
    end else begin
        $display("[%0t] FAIL: Pipeline latency mismatch", $time);
    end

    // 5. State transitions
    sequence high_co_in_calculation_state;
        (filter.control.present_state == filter.control.CALCULATION_STATE) && filter.counter_co;
    endsequence

    sequence low_co_in_calculation_state;
        (filter.control.present_state == filter.control.CALCULATION_STATE) && !filter.counter_co;
    endsequence

    sequence calculation_state_to_output;
        high_co_in_calculation_state ##1 (filter.control.present_state == filter.control.OUTPUT_STATE);
    endsequence

    sequence calculation_state_to_itself;
        low_co_in_calculation_state ##1 (filter.control.present_state == filter.control.CALCULATION_STATE);
    endsequence

    property loading_and_calculation_state;
        @(posedge clk) (filter.control.present_state == filter.control.LOADING_STATE) |=> 
        calculation_state_to_output or calculation_state_to_itself;
    endproperty

    loading_to_calculation_state: assert property(loading_and_calculation_state) begin
        $display("[%0t] PASS: Proper transition LOADING -> CALCULATION", $time);
    end else begin
        $display("[%0t] FAIL: Incorrect LOADING -> CALCULATION transition", $time);
    end

    // 6. input_valid triggers load_input
    input_valid_assert: assert property (@(posedge clk) input_valid |=> filter.load_input) begin
        $display("[%0t] PASS: input_valid triggers load_input", $time);
    end else begin
        $display("[%0t] FAIL: input_valid did not trigger load_input", $time);
    end

    // 7. ready_for_input implies input_valid low
    ready_input_assert: assert property (@(posedge clk) ready_for_input |-> !input_valid) begin
        $display("[%0t] PASS: ready_for_input implies input_valid low", $time);
    end else begin
        $display("[%0t] FAIL: ready_for_input but input_valid still high", $time);
    end

    // 8. FIR output width check
    output_width_assert: assert property (@(posedge clk) $bits(FIR_output) <= 38) begin
        $display("[%0t] PASS: FIR_output width within expected limit", $time);
    end else begin
        $display("[%0t] FAIL: FIR_output width exceeds 38 bits", $time);
    end

    // 9. Check FIR output **only if a valid calculation was performed**
    always @(posedge clk) begin
        if (output_valid && filter.load_result) begin
            integer out_idx;
            out_idx = input_pipeline[PIPELINE_DEPTH-1];
            if (FIR_output === expected_values[out_idx]) begin
                $display("[%0t] PASS: FIR_output matches expected value (input index %0d)", $time, out_idx);
            end else begin
                $display("[%0t] FAIL: FIR_output mismatch (input index %0d)", $time, out_idx);
                $display("       Expected: %0d, Got: %0d", expected_values[out_idx], FIR_output);
            end
        end
    end

    initial begin
        #2 reset = 1'b1;
        input_valid = 1'b0;
        #5 reset = 1'b0;

        for (i = 0; i < 20; i = i + 1) begin
            @(posedge ready_for_input);
            FIR_input = inputs[i];
            input_valid = 1'b1;
            #20 input_valid = 1'b0;
        end

        repeat (PIPELINE_DEPTH + 5) @(posedge clk);

        $stop;
    end

endmodule

