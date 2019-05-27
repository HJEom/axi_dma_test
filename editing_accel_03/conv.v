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
    output wire        m_axis_tvalid,
    output wire [31:0] m_axis_tdata,
    output wire [3:0]  m_axis_tstrb,
    output wire        m_axis_tlast,
    input  wire        m_axis_tready,
    input  [5:0]  i_current_ic,
    input  [79:0] i_params,
    input         i_params_valid,
    input wire [23:0] i_pe_1_row,
    input wire [23:0] i_pe_2_row,
    input wire [23:0] i_pe_3_row,
    input wire [23:0] i_pe_4_row,
    input wire [23:0] i_pe_5_row,
    input wire        i_pe_valid,
    input wire        img_row_done,
    input             send_flg
);

	reg [71:0] w_reg;
	reg [7:0]  b_reg;

	wire signed [7:0] o_pe_11;
	wire signed [7:0] o_pe_12;
	wire signed [7:0] o_pe_13;

	wire signed [7:0] o_pe_21;
	wire signed [7:0] o_pe_22;
	wire signed [7:0] o_pe_23;

	wire signed [7:0] o_pe_31;
	wire signed [7:0] o_pe_32;
	wire signed [7:0] o_pe_33;

	wire o_pe_11_valid, o_pe_12_valid, o_pe_13_valid;
	wire o_pe_21_valid, o_pe_22_valid, o_pe_23_valid;
	wire o_pe_31_valid, o_pe_32_valid, o_pe_33_valid;

	wire [7:0] pe_sum_1, pe_sum_2, pe_sum_3;
	reg [7:0] pe_sum_1_reg, pe_sum_2_reg, pe_sum_3_reg;
	reg pe_sum_valid, pe_sum_valid_d;
   
	reg [23:0] ofm_d;
	wire [31:0] ofm_q;
	reg ofm_ce, ofm_we;
	reg [11:0] ofm_addr, ofm_addr_row;
	reg [5:0] ofm_addr_col;
    reg tvalid, tvalid_d;
    reg [31:0] tdata;
    reg tlast;
    reg send_flg_d, send_flg_dd, send_flg_ddd, img_row_done_d, img_row_done_dd, img_row_done_ddd;
    
	always@(posedge clk) begin
		if(!rstn) begin
			w_reg <= 72'd0;
			b_reg <= 8'd0;
		end
		else begin
			if(i_params_valid) begin
				w_reg <= i_params[71:0];
				b_reg <= i_params[79:72];
			end
		end
	end

////////////////////////////////////// operate conv with signed w_reg.

	pe pe_11(clk, rstn, w_reg[71:64], w_reg[63:56], w_reg[55:48], i_pe_1_row, i_pe_valid, o_pe_11, o_pe_11_valid);
	pe pe_12(clk, rstn, w_reg[47:40], w_reg[39:32], w_reg[31:24], i_pe_2_row, i_pe_valid, o_pe_12, o_pe_12_valid);
	pe pe_13(clk, rstn, w_reg[23:16], w_reg[15:8], w_reg[7:0], i_pe_3_row, i_pe_valid, o_pe_13, o_pe_13_valid);

	pe pe_21(clk, rstn, w_reg[71:64], w_reg[63:56], w_reg[55:48], i_pe_2_row, i_pe_valid, o_pe_21, o_pe_21_valid);
	pe pe_22(clk, rstn, w_reg[47:40], w_reg[39:32], w_reg[31:24], i_pe_3_row, i_pe_valid, o_pe_22, o_pe_22_valid);
	pe pe_23(clk, rstn, w_reg[23:16], w_reg[15:8], w_reg[7:0], i_pe_4_row, i_pe_valid, o_pe_23, o_pe_23_valid);

	pe pe_31(clk, rstn, w_reg[71:64], w_reg[63:56], w_reg[55:48], i_pe_3_row, i_pe_valid, o_pe_31, o_pe_31_valid);
	pe pe_32(clk, rstn, w_reg[47:40], w_reg[39:32], w_reg[31:24], i_pe_4_row, i_pe_valid, o_pe_32, o_pe_32_valid);
	pe pe_33(clk, rstn, w_reg[23:16], w_reg[15:8], w_reg[7:0], i_pe_5_row, i_pe_valid, o_pe_33, o_pe_33_valid);

	assign pe_sum_1 = o_pe_11 + o_pe_12 + o_pe_13;
	assign pe_sum_2 = o_pe_21 + o_pe_22 + o_pe_23;
	assign pe_sum_3 = o_pe_31 + o_pe_32 + o_pe_33;

	always@(posedge clk) begin
		if(!rstn) begin
			pe_sum_1_reg <= 8'd0;
			pe_sum_2_reg <= 8'd0;
			pe_sum_3_reg <= 8'd0;
			pe_sum_valid <= 1'b0;
			pe_sum_valid_d <= 1'b0;
		end
		else begin
			pe_sum_1_reg <= pe_sum_1;
			pe_sum_2_reg <= pe_sum_2;
			pe_sum_3_reg <= pe_sum_3;
			pe_sum_valid <= o_pe_33_valid;
			pe_sum_valid_d <= pe_sum_valid;
		end
	end

	fifo_ofm#(8,2304) ofm_buffer(clk, rstn, ofm_ce, ofm_we, ofm_addr, ofm_d, ofm_q);

	always@(*) begin
		if(pe_sum_valid) begin
			ofm_ce = 1'b1;
			ofm_we = 1'b1;
			ofm_d = {pe_sum_1_reg, pe_sum_2_reg, pe_sum_3_reg};
		end
		else if(tvalid) begin
			ofm_ce = 1'b1;
			ofm_we = 1'b0;
		end
		else begin
			ofm_ce = 1'b0;
			ofm_we = 1'b0;
			ofm_d = 24'd0;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			ofm_addr <= 12'd0;
		end
		else begin
			if(o_pe_33_valid) begin
				ofm_addr <= ofm_addr_col + ofm_addr_row;
			end
			else if(ofm_addr == 12'd2207) ofm_addr <= 12'd0;
			else if(tvalid && m_axis_tready) begin
				ofm_addr <= ofm_addr + 3'd4;
			end
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			ofm_addr_row <= 12'd0;
		end
		else begin
            if(ofm_addr_row == 12'd2304) ofm_addr_row <= 12'd0;
			else if(img_row_done_dd) ofm_addr_row <= ofm_addr_row + 8'd144;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			ofm_addr_col <= 6'd0;
		end
		else begin
			if((pe_sum_valid) && (ofm_addr_col == 6'd47)) ofm_addr_col <= 6'd0;
			else if(o_pe_33_valid) ofm_addr_col <= ofm_addr_col + 1'b1;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			img_row_done_d <= 1'b0;
			img_row_done_dd <= 1'b0;
		end
		else begin
			img_row_done_d <= img_row_done;
			img_row_done_dd <= img_row_done_d; 
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			send_flg_d <= 1'b0;
			send_flg_dd <= 1'b0;
			send_flg_ddd <= 1'b0;
		end
		else begin
			send_flg_d <= send_flg;
			send_flg_dd <= send_flg_d;
			send_flg_ddd <= send_flg_dd;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin	
			tvalid <= 1'b0;
			tvalid_d <= 1'b0;
			tdata <= 32'd0;
		end
		else begin
			if(send_flg_ddd) tvalid <= 1'b1;
			else if(ofm_addr == 12'd2300) tvalid <= 1'b0;
			tdata <= ofm_q;
			tvalid_d <= tvalid;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			tlast <= 1'b0;
		end
		else begin
			if((tvalid) && (ofm_addr == 12'd2300)) tlast <= 1'b1;
			else tlast <= 1'b0;
		end
	end
	
	assign m_axis_tvalid = tvalid_d;
	assign m_axis_tlast = tlast;
	assign m_axis_tdata = tdata;
	assign m_axis_tstrb = 4'b1111;

endmodule
