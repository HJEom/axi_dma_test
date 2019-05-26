`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: out_buffer
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


module out_buffer(
    input  wire        clk,
    input  wire        rstn,
    output wire        m_axis_tvalid,
    output wire [31:0] m_axis_tdata,
    output wire [3:0]  m_axis_tstrb,
    output wire        m_axis_tlast,
    input  wire        m_axis_tready,
    input       [7:0]  pe_sum_1,
    input       [7:0]  pe_sum_2,
    input       [7:0]  pe_sum_3,
    input       [7:0]  pe_sum_4,
    input       [7:0]  pe_sum_5,
    input              pe_sum_valid,
    input       [5:0]  c_i_c,
    input              conv_done,
    input              conv_done_1,
    input              conv_done_2
);

    localparam OFM_PIXELS = 2304;
	
	(* ram_style = {"block"} *) reg [7:0] ofm_buffer[0:OFM_PIXELS-1];
	reg [11:0] wr_ptr;

	always@(posedge clk) begin
		if((pe_sum_valid) && (c_i_c == 6'd0)) begin
			ofm_buffer[wr_ptr] <= pe_sum_1;
			ofm_buffer[wr_ptr+1] <= pe_sum_2;
			ofm_buffer[wr_ptr+2] <= pe_sum_3;
			ofm_buffer[wr_ptr+3] <= pe_sum_4;
			ofm_buffer[wr_ptr+4] <= pe_sum_5;
		end
		else if(pe_sum_valid) begin
			ofm_buffer[wr_ptr] <= ofm_buffer[wr_ptr] + pe_sum_1;
			ofm_buffer[wr_ptr+1] <= ofm_buffer[wr_ptr+1] + pe_sum_2;
			ofm_buffer[wr_ptr+2] <= ofm_buffer[wr_ptr+2] + pe_sum_3;
			ofm_buffer[wr_ptr+3] <= ofm_buffer[wr_ptr+3] + pe_sum_4;
			ofm_buffer[wr_ptr+4] <= ofm_buffer[wr_ptr+4] + pe_sum_5;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			wr_ptr <= 12'd0;
		end
		else begin
			if(pe_sum_valid) wr_ptr <= wr_ptr + 1'b1;
			else if(wr_ptr == 12'd2047) wr_ptr <= 12'd0;
		end
	end



	wire tvalid;
	reg tvalid_delay;
	reg tlast;
	reg [31:0] tdata;
	reg [11:0] read_ptr;
	wire send_flg;
	reg in_last_delay_1;
	reg out_flg;
	reg in_delay_1;

	always@(posedge clk) begin
		if(!rstn) begin
			in_last_delay_1 <= 1'b0;
			in_delay_1 <= 1'b0;
		end
		else begin
			in_delay_1 <= conv_done_1;
			in_last_delay_1 <= conv_done_2;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			out_flg <= 1'b0;
		end
		else begin
			if(in_delay_1) out_flg <= 1'b1;
			else if(read_ptr == 12'd2047) out_flg <= 1'b0;
		end
	end

	assign tvalid = out_flg;

	assign send_flg = (tvalid && m_axis_tready) ? 1'b1 : 1'b0;

	always@(posedge clk) begin
		if(!rstn) begin
			read_ptr <= 12'd0;
		end
		else begin
			if(read_ptr == 12'd2047) read_ptr <= 12'd0;
			else if(send_flg) read_ptr <= read_ptr + 1'b1;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			tdata <= 32'd0;
			tvalid_delay <= 1'b0;
		end
		else begin
			if(send_flg) begin
				tdata <= ofm_buffer[read_ptr];
				tvalid_delay <= tvalid;
			end
			else tvalid_delay <= 1'b0;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			tlast <= 1'b0;
		end
		else begin
			if(in_last_delay_1) tlast <= 1'b1;
			else tlast <= 1'b0;
		end
	end

	assign m_axis_tstrb = 4'b1111;
	assign m_axis_tdata = tdata;
	assign m_axis_tlast = tlast;
	assign m_axis_tvalid = tvalid_delay;

endmodule
