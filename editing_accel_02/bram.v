module bram #(parameter ADDR_WIDTH = 6, DATA_WIDTH = 8, DEPTH = 48) (
    input wire 			clk,
    input wire 			ce,
    input wire 			we,
    input wire [ADDR_WIDTH-1:0] addr, 
    input wire [DATA_WIDTH-1:0] i_data,
    output reg [DATA_WIDTH-1:0] o_data 
    );

    (* ram_style = {"block"} *) reg [DATA_WIDTH-1:0] memory [0:DEPTH-1]; 

always @ (posedge clk) begin
	if(ce) begin
		if(we) memory[addr] <= i_data;
		else o_data <= memory[addr];
	end
end

endmodule
