`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: m_axis
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


module m_axis(
    input  wire        clk,
    input  wire        rstn,
    output wire        m_axis_tvalid,
    output wire [31:0] m_axis_tdata,
    output wire [3:0]  m_axis_tstrb,
    output wire        m_axis_tlast,
    input  wire        m_axis_tready,
    input  wire [31:0] in_data,
    input  wire        in_valid,
    input  wire        in_last
);

	wire tvalid;
	reg tvalid_delay;
	reg tlast;
	reg [31:0] tdata;
    (* ram_style = "{block}" *)
	reg [31:0] m_fifo[0:1023];
	reg [9:0] fifo_ptr;
	reg [9:0] read_ptr;
	wire send_flg;
	reg in_last_delay_1, in_last_delay_2, in_last_delay_3;
	reg out_flg;

	always@(posedge clk) begin
		if(!rstn) begin
			in_last_delay_1 <= 1'b0;
			in_last_delay_2 <= 1'b0;
			in_last_delay_3 <= 1'b0;
		end
		else begin
			in_last_delay_1 <= in_last;
			in_last_delay_2 <= in_last_delay_1;
			in_last_delay_3 <= in_last_delay_2;
		end
	end

	always@(posedge clk) begin
		if(in_valid) m_fifo[fifo_ptr] <= in_data;
	end

	always@(posedge clk) begin
		if(!rstn) begin
			fifo_ptr <= 10'd0;
		end
		else begin
			if(in_valid) begin
				fifo_ptr <= fifo_ptr + 1'b1;
			end
			else if(fifo_ptr == 10'd800) fifo_ptr <= 10'd0;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			out_flg <= 1'b0;
		end
		else begin
			if(in_last_delay_3) out_flg <= 1'b1;
			else if(read_ptr == 10'd800) out_flg <= 1'b0;
		end
	end

	assign tvalid = (out_flg) ? 1'b1 : 1'b0;

	assign send_flg = (tvalid && m_axis_tready) ? 1'b1 : 1'b0;

	always@(posedge clk) begin
		if(!rstn) begin
			read_ptr <= 10'd0;
		end
		else begin
			if(read_ptr == 10'd800) read_ptr <= 10'd0;
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
				tdata <= m_fifo[read_ptr];
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
			if((out_flg) && (read_ptr == 10'd800)) tlast <= 1'b1;
			else tlast <= 1'b0;
		end
	end

	assign m_axis_tstrb = 4'b1111;
	assign m_axis_tdata = tdata;
	assign m_axis_tlast = tlast;
	assign m_axis_tvalid = tvalid_delay;

endmodule
