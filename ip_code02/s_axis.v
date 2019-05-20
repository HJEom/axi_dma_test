`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: s_axis
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


module s_axis(
    input  wire        clk,
    input  wire        rstn,
    output wire        s_axis_tready,
    input  wire [31:0] s_axis_tdata,
    input  wire [3:0]  s_axis_tstrb,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    output wire        out_last,
    output wire        out_valid,
    output wire [71:0] out_data
);


	localparam IDLE = 1'b0,
			RECEIVE_PIXELS  = 1'b1;

	reg c_state;  
	reg receive_done;
	reg  [71:0] pixels;
	reg pixels_valid;
	reg [9:0] pixels_ptr;
	reg pixels_last;

	wire rcv_en;
	wire tready;

	assign s_axis_tready = tready;
	assign out_data = pixels;
	assign out_valid = pixels_valid;
	assign out_last = pixels_last;

	always@(posedge clk) begin
		if(!rstn) begin
			c_state <= IDLE;
		end
		else begin
			case(c_state)
				IDLE : if(s_axis_tvalid) c_state <= RECEIVE_PIXELS;
				RECEIVE_PIXELS : if(receive_done) c_state <= IDLE;
			endcase
		end
	end

	assign tready = (c_state == RECEIVE_PIXELS);

	always@(posedge clk) begin
		if(!rstn) begin
			pixels_ptr <= 10'd0;
			receive_done <= 1'b0;
		end
		else begin
			if(rcv_en) begin
				pixels_ptr <= pixels_ptr + 1;
				receive_done <= 1'b0;
			end
			else if(c_state == IDLE) begin
				pixels_ptr <= 10'd0;
			end
			if(s_axis_tlast) begin
				receive_done <= 1'b1;
			end
		end
	end

	assign rcv_en = s_axis_tvalid && tready;

	always@(posedge clk) begin
		if(!rstn) begin
			pixels <= 72'd0;
			pixels_valid <= 1'b0;
		end
		else begin
			if(!(pixels_ptr==10'd32) || !(pixels_ptr==10'd64) || !(pixels_ptr==10'd96) || !(pixels_ptr==10'd128) || !(pixels_ptr==10'd160) || !(pixels_ptr==10'd192) || !(pixels_ptr==10'd224) || !(pixels_ptr==10'd256) || !(pixels_ptr==10'd288) || !(pixels_ptr==10'd320) || !(pixels_ptr==10'd352) || !(pixels_ptr==10'd384) || !(pixels_ptr==10'd416) || !(pixels_ptr==10'd448) || !(pixels_ptr==10'd480) || !(pixels_ptr==10'd512) || !(pixels_ptr==10'd544) || !(pixels_ptr==10'd576) || !(pixels_ptr==10'd608) || !(pixels_ptr==10'd640) || !(pixels_ptr==10'd672) || !(pixels_ptr==10'd704) || !(pixels_ptr==10'd736) || !(pixels_ptr==10'd768) || !(pixels_ptr==10'd800) || !(pixels_ptr==10'd832) || !(pixels_ptr==10'd864) || !(pixels_ptr==10'd896) || !(pixels_ptr==10'd928)) begin
				pixels <= {pixels[47:0], s_axis_tdata[23:0]};
			end
			else begin
				pixels <= {pixels[63:48],s_axis_tdata[23:16],pixels[39:24],s_axis_tdata[15:8],pixels[15:0],s_axis_tdata[7:0]};
			end
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pixels_valid <= 1'b0;
		end
		else begin
			if(pixels_ptr == 10'd2) pixels_valid <= 1'b1;
			else if(pixels_ptr == 10'd959 || s_axis_tlast) pixels_valid <= 1'b0;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pixels_last <= 1'b0;
		end
		else begin
			if(pixels_ptr == 10'd959 || s_axis_tlast) pixels_last <= 1'b1;
			else if(pixels_ptr == 10'd0) pixels_last <= 1'b0;
		end
	end
			

endmodule
