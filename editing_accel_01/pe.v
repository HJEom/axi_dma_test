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
    output signed [15:0]  o,
    output        o_valid
);

	wire signed [15:0] psum;
    wire signed [8:0] p1, p2, p3;
	reg signed [15:0] psum_reg;
	reg p_valid_d;

    assign p1 = {1'b0, p[23:16]};
    assign p2 = {1'b0, p[15:8]};
    assign p3 = {1'b0, p[7:0]};
	assign psum = w1*p1 + w2*p2 + w3*p3;

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

    assign o = (psum_reg>>>6);
	assign o_valid = p_valid_d;

endmodule
