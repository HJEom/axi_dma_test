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
    output [7:0]  o,
    output        o_valid
);

	wire signed [15:0] psum;

	reg [15:0] psum_reg;
	reg p_valid_d;
	reg [7:0] over_psum;

	assign psum = w1*p[23:16] + w2*p[15:8] + w3*p[7:0];

	always@(posedge clk) begin
		if(!rstn) begin
			psum_reg <= 16'd0;
		end
		else begin
			if(p_valid) psum_reg <= psum;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			p_valid_d <= 1'b0;
		end
		else begin
			p_valid_d <= p_valid;
		end
	end

	always@(*) begin
		if((p_valid_d) && !(psum_reg[15]) && (psum_reg[14:8] > 0)) over_psum = 8'b01111111;
		else if((p_valid_d) && (psum_reg[15]) && (psum_reg[14:8] > 0)) over_psum = 8'b10000000;
		else over_psum = psum_reg;
	end

	assign o = over_psum;
	assign o_valid = p_valid_d;

endmodule
