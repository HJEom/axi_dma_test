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
    input  [25:0] i_param,
    input         i_param_valid,
    input  [23:0] pe_1,
    input  [23:0] pe_2,
    input  [23:0] pe_3,
    input  [23:0] pe_4,
    input  [23:0] pe_5,
    input  [23:0] pe_6,
    input  [23:0] pe_7,
    input         pe_valid,
);

	localparam OFM_PIXELS = 2304;

	reg [79:0] params; // [79:8] weights, [7:0] bias
	wire signed o_pe_11, o_pe_12, o_pe_13;
	wire signed o_pe_21, o_pe_22, o_pe_23;
	wire signed o_pe_31, o_pe_32, o_pe_33;
	wire signed o_pe_41, o_pe_42, o_pe_43;
	wire signed o_pe_51, o_pe_52, o_pe_53;
	wire o_pe_11_valid, o_pe_12_valid, o_pe_13_valid;
	wire o_pe_21_valid, o_pe_22_valid, o_pe_23_valid;
	wire o_pe_31_valid, o_pe_32_valid, o_pe_33_valid;
	wire o_pe_41_valid, o_pe_42_valid, o_pe_43_valid;
	wire o_pe_51_valid, o_pe_52_valid, o_pe_53_valid;

	wire signed [17:0] pe_sum_1, pe_sum_2, pe_sum_3, pe_sum_4, pe_sum_5;
	reg [7:0] pe_sum_1_reg, pe_sum_2_reg, pe_sum_3_reg, pe_sum_4_reg, pe_sum_5_reg;
	reg [8:0] ofm_buffer[0:OFM_PIXELS-1];

	always@(posedge clk) begin
		if(!rstn) begin
			params <= 80'd0;
		end
		else begin
			if(i_param_valid)
				case(i_param[25:24])
					2'd0 : params <= {params[55:0], i_param[23:0]};
					2'd1 : params <= {params[71:0], i_param[7:0]};
				endcase
			end
		end
	end

	pe pe_11(clk, rstn, params[79:72], params[71:64], params[63:56], pe_1, pe_valid, o_pe_11, o_pe_11_valid);
	pe pe_12(clk, rstn, params[55:48], params[47:40], params[39:32], pe_2, pe_valid, o_pe_12, o_pe_12_valid);
	pe pe_13(clk, rstn, params[31:16], params[15:8], params[7:0], pe_3, pe_valid, o_pe_13, o_pe_13_valid);

	pe pe_21(clk, rstn, params[79:72], params[71:64], params[63:56], pe_2, pe_valid, o_pe_21, o_pe_21_valid);
	pe pe_22(clk, rstn, params[55:48], params[47:40], params[39:32], pe_3, pe_valid, o_pe_22, o_pe_22_valid);
	pe pe_23(clk, rstn, params[31:16], params[15:8], params[7:0], pe_4, pe_valid, o_pe_23, o_pe_23_valid);

	pe pe_31(clk, rstn, params[79:72], params[71:64], params[63:56], pe_3, pe_valid, o_pe_31, o_pe_31_valid);
	pe pe_32(clk, rstn, params[55:48], params[47:40], params[39:32], pe_4, pe_valid, o_pe_32, o_pe_32_valid);
	pe pe_33(clk, rstn, params[31:16], params[15:8], params[7:0], pe_5, pe_valid, o_pe_33, o_pe_33_valid);

	pe pe_41(clk, rstn, params[79:72], params[71:64], params[63:56], pe_4, pe_valid, o_pe_41, o_pe_41_valid);
	pe pe_42(clk, rstn, params[55:48], params[47:40], params[39:32], pe_5, pe_valid, o_pe_42, o_pe_42_valid);
	pe pe_43(clk, rstn, params[31:16], params[15:8], params[7:0], pe_6, pe_valid, o_pe_43, o_pe_43_valid);

	pe pe_51(clk, rstn, params[79:72], params[71:64], params[63:56], pe_5, pe_valid, o_pe_51, o_pe_51_valid);
	pe pe_52(clk, rstn, params[55:48], params[47:40], params[39:32], pe_6, pe_valid, o_pe_52, o_pe_52_valid);
	pe pe_53(clk, rstn, params[31:16], params[15:8], params[7:0], pe_7, pe_valid, o_pe_53, o_pe_53_valid);

	assign pe_sum_1 = o_pe_11 + o_pe_12 + o_pe_13;
	assign pe_sum_2 = o_pe_21 + o_pe_22 + o_pe_23;
	assign pe_sum_3 = o_pe_31 + o_pe_32 + o_pe_33;
	assign pe_sum_4 = o_pe_41 + o_pe_42 + o_pe_43;
	assign pe_sum_5 = o_pe_51 + o_pe_52 + o_pe_53;

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_1_reg <= 8'd0;
		end
		else begin
			if((o_pe_11_valid) && !(pe_sum_1[17]) && (pe_sum_1[16:8] > 0)) pe_sum_1_reg <= 8'b01111111;
			else if((o_pe_11_valid) && (pe_sum_1[17]) && (pe_sum_1[16:8] > 0)) pe_sum_1_reg <= 8'b10000000;
			else pe_sum_1_reg <= pe_sum_1;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_2_reg <= 8'd0;
		end
		else begin
			if((o_pe_21_valid) && !(pe_sum_2[17]) && (pe_sum_2[16:8] > 0)) pe_sum_2_reg <= 8'b01111111;
			else if((o_pe_21_valid) && (pe_sum_2[17]) && (pe_sum_2[16:8] > 0)) pe_sum_2_reg <= 8'b10000000;
			else pe_sum_2_reg <= pe_sum_2;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_3_reg <= 8'd0;
		end
		else begin
			if((o_pe_31_valid) && !(pe_sum_3[17]) && (pe_sum_3[16:8] > 0)) pe_sum_3_reg <= 8'b01111111;
			else if((o_pe_31_valid) && (pe_sum_3[17]) && (pe_sum_3[16:8] > 0)) pe_sum_3_reg <= 8'b10000000;
			else pe_sum_3_reg <= pe_sum_3;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_4_reg <= 8'd0;
		end
		else begin
			if((o_pe_41_valid) && !(pe_sum_4[17]) && (pe_sum_4[16:8] > 0)) pe_sum_4_reg <= 8'b01111111;
			else if((o_pe_41_valid) && (pe_sum_4[17]) && (pe_sum_4[16:8] > 0)) pe_sum_4_reg <= 8'b10000000;
			else pe_sum_4_reg <= pe_sum_4;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_5_reg <= 8'd0;
		end
		else begin
			if((o_pe_51_valid) && !(pe_sum_5[17]) && (pe_sum_5[16:8] > 0)) pe_sum_5_reg <= 8'b01111111;
			else if((o_pe_51_valid) && (pe_sum_5[17]) && (pe_sum_5[16:8] > 0)) pe_sum_5_reg <= 8'b10000000;
			else pe_sum_5_reg <= pe_sum_5;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_delay<= 1'b0;
		end
		else begin
			pe_sum_delay <= o_pe_51_valid;
		end
	end

	always@(posedge clk) begin
		if(pe_sum_delay) begin
			ofm_buffer[wr_ptr] <= pe_sum_1_reg;
			ofm_buffer[wr_ptr+1] <= pe_sum_2_reg;
			ofm_buffer[wr_ptr+2] <= pe_sum_3_reg;
			ofm_buffer[wr_ptr+3] <= pe_sum_4_reg;
			ofm_buffer[wr_ptr+4] <= pe_sum_5_reg;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			wr_ptr <= 12'd0;
		end
		else begin
			if(pe_sum_delay) wr_ptr <= wr_ptr + 1'b1;
			else if(wr_ptr == 12'd2047) wr_ptr <= 12'd0;
		end
	end

	





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
