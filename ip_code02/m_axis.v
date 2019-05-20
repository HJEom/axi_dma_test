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

	reg tvalid;
	reg [31:0] tdata;
	reg last_delay_1, last_delay_2, last_delay_3;

	always@(posedge clk) begin
		if(!rstn) begin
			tdata <= 32'd0;
			tvalid <= 1'b0;
		end
		else begin
			if(in_valid) begin
				tdata <= in_data;
				tvalid <= 1'b1;
			end
			else tvalid <= 1'b0;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			last_delay_1 <= 1'b0;
			last_delay_2 <= 1'b0;
			last_delay_3 <= 1'b0;
		end
		else begin
			last_delay_1 <= in_last;
			last_delay_2 <= last_delay_1;
			last_delay_3 <= last_delay_2;
		end
	end

	assign m_axis_tstrb = 4'b1111;
	assign m_axis_tdata = tdata;
	assign m_axis_tlast = last_delay_3;
	assign m_axis_tvalid = tvalid;

endmodule
