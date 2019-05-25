`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: in_buffer
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


module in_buffer(
    input  wire        clk,
    input  wire        rstn,
    output wire        s_axis_tready,
    input  wire [31:0] s_axis_tdata,
    input  wire [3:0]  s_axis_tstrb,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    input  wire        i_state,
    input  wire [1:0]  i_layer,
    input  wire        i_last,    ////////////////////////////// assign m_axis_tlast
    output wire [3:0] leds
);


	localparam IDLE = 2'd0,
			WEIGHTS_LOAD = 2'd1,
			IMAGES_LOAD = 2'd2,
			SEND_DATA = 2'd3;

	localparam WEIGHTS_NUMBER = 38016;
	localparam BIAS_NUMBER = 129;
	localparam IMAGES_NUMBER = 49512;

	wire tready;

	reg [1:0] c_state;

	(* ram_style = {"block"} *) reg [23:0] w_buffer[0:WEIGHTS_NUMBER-1];
	(* ram_style = {"block"} *) reg [7:0] b_buffer[0:BIAS_NUMBER-1];
	(* ram_style = {"block"} *) reg [23:0] img_buffer[0:IMAGES_NUMBER-1];
	reg [15:0] buffer_wr_ptr;
	reg [15:0] rd_images_ptr;
	reg [15:0] rd_weights_ptr;
	reg [7:0] rd_bias_ptr;
	reg weights_load_done;
    reg images_load_done;
    
    wire wr_en;

	assign s_axis_tready = tready;

	always@(posedge clk) begin
		if(!rstn) begin
			c_state <= IDLE;
		end
		else begin
			case(c_state)
				IDLE : begin
					if(s_axis_tvalid) begin
						case(i_state)
							1'b0 : c_state <= WEIGHTS_LOAD;
							1'b1 : c_state <= IMAGES_LOAD;
						endcase
					end
				end
				WEIGHTS_LOAD : begin
					if(weights_load_done) c_state <= IDLE;
				end
				IMAGES_LOAD : begin
					if(images_load_done) c_state <= SEND_DATA;
				end
				SEND_DATA : begin
					if(i_last) c_state <= IDLE;
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			weights_load_done <= 1'b0;
			images_load_done <= 1'b0;
		end
		else begin
			case(c_state)
				WEIGHTS_LOAD : if(s_axis_tlast) weights_load_done <= 1'b1;
				IMAGES_LOAD : if(s_axis_tlast) images_load_done <= 1'b1;
				default : begin
					weights_load_done <= 1'b0;
					images_load_done <= 1'b0;
				end
			endcase
		end
	end

	assign tready = ((c_state == WEIGHTS_LOAD) || (c_state == IMAGES_LOAD));

	always@(posedge clk) begin
		if((c_state == WEIGHTS_LOAD) && (wr_en)) w_buffer[buffer_wr_ptr] <= s_axis_tdata[23:0];
	end

	always@(posedge clk) begin
		if((c_state == WEIGHTS_LOAD) && (wr_en) && (buffer_wr_ptr <= BIAS_NUMBER-1)) b_buffer[buffer_wr_ptr] <= s_axis_tdata[31:24];
	end

	always@(posedge clk) begin
		if((c_state == IMAGES_LOAD) && (wr_en)) img_buffer[buffer_wr_ptr] <= s_axis_tdata[23:0];
	end

	assign wr_en = s_axis_tvalid && tready;

	always@(posedge clk) begin
		if(!rstn) begin
			buffer_wr_ptr <=16'd0;
		end
		else begin
			case(c_state)
				WEIGHTS_LOAD : begin
					if(wr_en) buffer_wr_ptr <= buffer_wr_ptr + 1'b1;
				end
				IMAGES_LOAD : begin
					if(wr_en) buffer_wr_ptr <= buffer_wr_ptr + 1'b1;
				end
				default : buffer_wr_ptr <= 16'd0;
			endcase
		end
	end

	assign leds = {weights_load_done, 2'b00, images_load_done};

endmodule
