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
    output [7:0]  pe_sum_1_wire,
    output [7:0]  pe_sum_2_wire,
    output [7:0]  pe_sum_3_wire,
    output [7:0]  pe_sum_4_wire,
    output [7:0]  pe_sum_5_wire,
    output        pe_sum_n_delay
);



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
	reg pe_sum_delay;

	assign pe_sum_n_delay = pe_sum_delay;
	assign pe_sum_1_wire = pe_sum_1_reg;
	assign pe_sum_2_wire = pe_sum_2_reg;
	assign pe_sum_3_wire = pe_sum_3_reg;
	assign pe_sum_4_wire = pe_sum_4_reg;
	assign pe_sum_5_wire = pe_sum_5_reg;
	
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

endmodule
