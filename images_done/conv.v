`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: conv
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


module conv(
    input         clk,
    input         rstn,
    input  [71:0] w,
    input         w_valid,
    input  [71:0] p,
    input         p_valid,
    output [31:0] o,
    output        o_valid
);

	reg [71:0]  w_reg;
	reg [71:0]  p_reg;
	reg         w_done;
	reg         p_done;
	reg         conv_done;
	reg [31:0]  add;

	reg [15:0] tmp_add_1;
	reg [15:0] tmp_add_2;
	reg [15:0] tmp_add_3;
	reg [15:0] tmp_add_4;
	reg [15:0] tmp_add_5;
	reg [15:0] tmp_add_6;
	reg [15:0] tmp_add_7;
	reg [15:0] tmp_add_8;
	reg [15:0] tmp_add_9;
	reg [16:0] tmp_add;

	always@(posedge clk) begin
		if(!rstn) begin
			w_reg <= 72'd0;
			w_done <= 1'b0;
		end
		else begin
			if(w_valid) begin
				w_reg <= w;
				w_done <= 1'b1;
			end
			else begin
				w_done <= 1'b0;
			end
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			p_reg <= 72'd0;
			p_done <= 1'b0;
		end
		else begin
			if(p_valid) begin
				p_reg <= p;
				p_done <= 1'b1;
			end
			else begin
				p_done <= 1'b0;
			end
		end
	end

	always@(*) begin
		if(w_done && p_done) begin
			tmp_add_1 = w_reg[7:0]*p_reg[7:0];
			tmp_add_2 = w_reg[15:8]*p_reg[15:8];
			tmp_add_3 = w_reg[23:16]*p_reg[23:16];
			tmp_add_4 = w_reg[31:24]*p_reg[31:24];
			tmp_add_5 = w_reg[39:32]*p_reg[39:32];
			tmp_add_6 = w_reg[47:40]*p_reg[47:40];
			tmp_add_7 = w_reg[55:48]*p_reg[55:48];
			tmp_add_8 = w_reg[63:56]*p_reg[63:56];
			tmp_add_9 = w_reg[71:64]*p_reg[71:64];
			tmp_add = tmp_add_1 + tmp_add_2 + tmp_add_3 + tmp_add_4 + tmp_add_5 + tmp_add_6 + tmp_add_7 + tmp_add_8 + tmp_add_9;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			conv_done <= 1'b0;
		end
		else begin
			if(w_done && p_done) begin
				conv_done <= 1'b1;
			end
			else begin
				conv_done <= 1'b0;
			end	
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			add <= 32'd0;
		end
		else begin
			if(w_done && p_done) begin
				add <= {{(15){1'b0}}, tmp_add};
			end
		end
	end

	assign o_valid = conv_done;
	assign o = add;


endmodule
