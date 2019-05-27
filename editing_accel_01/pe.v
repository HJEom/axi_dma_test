`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pe(
    input         clk,
    input         rstn,
    input signed [7:0] w1,
    input signed [7:0] w2,
    input signed [7:0] w3,
    input  [23:0] p,
    input         p_valid,
    output [16:0] o,
    output        o_valid
);

	wire signed [16:0] ppsum;
	reg [16:0] psum;
	reg o_valid_delay;

	assign ppsum = (p_valid) ? w1*p[23:16] + w2*p[15:8] + w3*p[7:0] : 17'd0;

	always@(posedge clk) begin
		if(!rstn) begin
			psum <= 17'd0;
			o_valid_delay <= 1'b0;
		end
		else begin
			if(p_valid) begin
				psum <= ppsum;
				o_valid_delay <= 1'b1;
			end
			else o_valid_delay <= 1'b0;
		end
	end

	

	assign o = psum;
	assign o_valid = o_valid_delay;

endmodule
