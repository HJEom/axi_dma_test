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
);


	localparam IDLE = 3'd0,
			WEIGHTS_LOAD = 3'd1,
			IMAGES_LOAD = 3'd2,
			SEND_WEIGHTS = 3'd3,
			SEND_BIAS = 3'd4,
			SEND_IMAGES = 3'd5;

	localparam SEND_IMAGES_FIRST_ROW = 2'd0,
			SEND_IMAGES_MIDDLE_ROW = 2'd1,
			SEND_IMAGES_LAST_ROW = 2'd2;

	localparam WEIGHTS_NUMBER = 38016;
	localparam BIAS_NUMBER = 129;
	localparam IMAGES_NUMBER = 49512;

	wire tready;

	reg [2:0] c_state;
	reg [1:0] img_state;

	(* ram_style = {"block"} *) reg [23:0] w_buffer[0:WEIGHTS_NUMBER-1];
	(* ram_style = {"block"} *) reg [7:0] b_buffer[0:BIAS_NUMBER-1];
	(* ram_style = {"block"} *) reg [23:0] img_buffer[0:IMAGES_NUMBER-1];
	reg [15:0] buffer_wr_ptr;
	reg [15:0] rd_images_ptr;
	reg weights_load_done;
	reg images_load_done;
	reg [5:0] i_c;
	reg [5:0] o_c;
	reg [5:0] c_i_c;
	reg [5:0] c_o_c;
	reg [5:0] data_cnt;
    
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
				SEND_WEIGHTS : begin
					if(data_cnt == 6'd2) c_state <= SEND_BIAS;
				end
				SEND_BIAS : begin
					if(data_cnt == 6'd0) c_state <= SEND_IMAGES;
				end
				SEND_IMAGES : begin
					if(conv_done) begin
						if(i_last) c_state <= IDLE;
						else c_state <= SEND_WEIGHTS;
					end
				end
				default : c_state <= IDLE;
			endcase
		end
	end

	always@(*) begin
		case(i_layer)
			2'd0 : begin
				i_c = 6'd0;
				o_c = 6'd63;
			end
			2'd1 : begin
				i_c = 6'd63;
				o_c = 6'd63;
			end
			2'd2 : begin
				i_c = 6'd63;
				o_c = 6'd0;
			end
			default : begin
				i_c = 6'd0;
				o_c = 6'd0;
			end
		endcase
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

	always@(posedge clk) begin
		if(!rstn) begin
			data <= 26'd0; // MSB 2-bit : (00) : w, (01) : b, (10) : img
			data_valid <= 1'b0;
			pe_1 <= 24'd0;
			pe_2 <= 24'd0;
			pe_3 <= 24'd0;
			pe_4 <= 24'd0;
			pe_5 <= 24'd0;
			pe_6 <= 24'd0;
			pe_7 <= 24'd0;
		end
		else begin
			case(c_state)
				SEND_WEIGHTS : begin
					case(i_layer)
						2'd0 : data <= {2'b00, w_buffer[c_i_c*3+c_o_c*3+data_cnt]};
						2'd1 : data <= {2'b00, w_buffer[192+c_i_c*3+c_o_c*3+data_cnt]};
						2'd2 : data <= {2'b00, w_buffer[12480+c_i_c*3+c_o_c*3+data_cnt]};
					endcase
					data_valid <= 1'b1;
				end
				SEND_BIAS : begin
					case(i_layer)
						2'd0 : data <= {2'b01, 16'd0, b_buffer[c_o_c]};
						2'd1 : data <= {2'b01, 16'd0, b_buffer[64+c_o_c]};
						2'd2 : data <= {2'b01, 16'd0, b_buffer[128+c_o_c]};
					endcase
					data_valid <= 1'b1;
				end
				SEND_IMAGES : begin
					case(img_state)
						SEND_IMAGES_FIRST_ROW : begin
							if(data_cnt == 6'd49) begin
								pe_1 <= 24'd0;
								pe_2 <= {pe_2[15:0], 8'd0};
								pe_3 <= {pe_3[15:0], 8'd0};
								pe_4 <= {pe_4[15:0], 8'd0};
								pe_5 <= {pe_5[15:0], 8'd0};
								pe_6 <= {pe_6[15:0], 8'd0};
								pe_7 <= {pe_7[15:0], 8'd0};
							end
							else begin
								pe_1 <= 24'd0;
								pe_2 <= {pe_2[15:0], img_buffer[c_o_c*768+16*(c_r)+fifo_r+pixel_cnt]};
								pe_3 <= {pe_3[15:0], img_buffer[c_o_c*768+16*(c_r+1'b1)+fifo_r+pixel_cnt]};
								pe_4 <= {pe_4[15:0], img_buffer[c_o_c*768+16*(c_r+2'd2)+fifo_r+pixel_cnt]};
								pe_5 <= {pe_5[15:0], img_buffer[c_o_c*768+16*(c_r+2'd3)+fifo_r+pixel_cnt]};
								pe_6 <= {pe_6[15:0], img_buffer[c_o_c*768+16*(c_r+3'd4)+fifo_r+pixel_cnt]};
								pe_7 <= {pe_7[15:0], img_buffer[c_o_c*768+16*(c_r+3'd5)+fifo_r+pixel_cnt]};
							end
						end
						SEND_IMAGES_MIDDLE_ROW : begin
							if(data_cnt == 6'd49) begin
								pe_1 <= {pe_1[15:0], 8'd0};
								pe_2 <= {pe_2[15:0], 8'd0};
								pe_3 <= {pe_3[15:0], 8'd0};
								pe_4 <= {pe_4[15:0], 8'd0};
								pe_5 <= {pe_5[15:0], 8'd0};
								pe_6 <= {pe_6[15:0], 8'd0};
								pe_7 <= {pe_7[15:0], 8'd0};
							end
							else begin
								pe_1 <= {pe_1[15:0], img_buffer[c_o_c*768+16*(c_r)+fifo_r+pixel_cnt]};
								pe_2 <= {pe_2[15:0], img_buffer[c_o_c*768+16*(c_r+1'b1)+fifo_r+pixel_cnt]};
								pe_3 <= {pe_3[15:0], img_buffer[c_o_c*768+16*(c_r+2'd2)+fifo_r+pixel_cnt]};
								pe_4 <= {pe_4[15:0], img_buffer[c_o_c*768+16*(c_r+2'd3)+fifo_r+pixel_cnt]};
								pe_5 <= {pe_5[15:0], img_buffer[c_o_c*768+16*(c_r+3'd4)+fifo_r+pixel_cnt]};
								pe_6 <= {pe_6[15:0], img_buffer[c_o_c*768+16*(c_r+3'd5)+fifo_r+pixel_cnt]};
								pe_7 <= {pe_7[15:0], img_buffer[c_o_c*768+16*(c_r+3'd6)+fifo_r_pixel_cnt]};
							end
						end
						SEND_IMAGES_LAST_ROW : begin
							if(data_cnt == 6'd49) begin
								pe_1 <= {pe_1[15:0], 8'd0};
								pe_2 <= {pe_2[15:0], 8'd0};
								pe_3 <= {pe_3[15:0], 8'd0};
								pe_4 <= {pe_4[15:0], 8'd0};
								pe_5 <= {pe_5[15:0], 8'd0};
								pe_6 <= {pe_6[15:0], 8'd0};
								pe_7 <= 24'd0;
							end
							else begin
								pe_1 <= {pe_1[15:0], img_buffer[c_o_c*768+16*(c_r)+fifo_r+pixel_cnt]};
								pe_2 <= {pe_2[15:0], img_buffer[c_o_c*768+16*(c_r+1'b1)+fifo_r+pixel_cnt]};
								pe_3 <= {pe_3[15:0], img_buffer[c_o_c*768+16*(c_r+2'd2)+fifo_r+pixel_cnt]};
								pe_4 <= {pe_4[15:0], img_buffer[c_o_c*768+16*(c_r+2'd3)+fifo_r+pixel_cnt]};
								pe_5 <= {pe_7[15:0], img_buffer[c_o_c*768+16*(c_r+3'd4)+fifo_r+pixel_cnt]};
								pe_6 <= {pe_6[15:0], img_buffer[c_o_c*768+16*(c_r+3'd5)+fifo_r+pixel_cnt]};
								pe_7 <= 24'd0;
							end
						end
					endcase
					data_valid <= 1'b0;
					if((c_state == SEND_IMAGES) && (data_cnt == 6'd1)) pe_valid <= 1'b1;
					else if(c_state == SEND_WEIGHTS || (data_cnt == 6'd49)) pe_valid <= 1'b0;
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			img_state <= SEND_IMAGES_FIRST_ROW;
		end
		else begin
			if(c_state == SEND_IMAGES)
			case(img_state)
				SEND_IMAGES_FIRST_ROW  : begin
					if((pixel_cnt == 2'd2) && (fifo_r == 4'd15)) img_state <= SEND_IMAGES_MIDDLE_ROW;
				end
				SEND_IMAGES_MIDDLE_ROW  : begin
					if((pixel_cnt == 2'd2) && (fifo_r == 4'd15) && (c_r == 6'd41)) img_state <= SEND_IMAGES_LAST_ROW;
				end
				SEND_IMAGES_LAST_ROW  : begin
					if((pixel_cnt == 2'd2) && (fifo_r == 4'd15) && (c_r == 6'd42)) img_state <= SEND_IMAGES_FIRST_ROW;
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			data_cnt <= 6'd0;
			pixel_cnt <= 2'd0;
			c_r <= 6'd0;
			fifo_r <= 4'd0;
		end
		else begin
			case(c_state)
				SEND_WEIGHTS : begin
					if(data_cnt == 6'd2) data_cnt <= 6'd0;
					else data_cnt <= data_cnt + 1'b1;
				end
				SEND_IMAGES : begin
					if(pixel_cnt == 2'd2) begin
						pixel_cnt <= 2'd0;
						if(fifo_r == 4'd15) begin
							fifo_r <= 4'd0;
							if(c_r == 6'd42) c_r <= 6'd0;
							else c_r <= c_r + 1'b1;
						end
						else fifo_r <= fifo_r + 1'b1;
					end
					else pixel_cnt <= pixel_cnt + 1'b1;
				end
				default : data_cnt <= 6'd0;
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			c_i_c <= 6'd0;
		end
		else begin
			if(c_i_c == i_c) c_i_c <= 6'd0;
			else if(conv_done) c_i_c <= c_i_c + 1'b1;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			c_o_c <= 6'd0;
		end
		else begin
			if(i_last) c_o_c <= 6'd0;
			else if((c_i_c == i_c) && (conv_done)) c_o_c <= c_o_c + 1'b1;
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			conv_done <= 1'b0;
			conv_done_delay <= 1'b0;
			conv_done_delay_delay <= 1'b0;
		end
		else begin
			if((data_

endmodule
