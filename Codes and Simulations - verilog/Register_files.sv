`timescale 1ns/1ns

module regFile#(parameter WIDTH = 16, parameter LENGTH = 6) 
        (address, out_put);

    parameter ADDRESS_BIT = $clog2(LENGTH);
    input[ADDRESS_BIT-1:0] address;
    output[WIDTH-1:0] out_put;

    reg signed [WIDTH - 1:0] data [0:LENGTH-1];

    initial
	    begin
		    $readmemb("coeffs.txt",data);
	    end

    assign out_put = data[address];
  

endmodule
