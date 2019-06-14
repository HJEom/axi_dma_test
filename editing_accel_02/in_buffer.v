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
    input  wire [1:0]  i_state,
    output wire        o_state_cnvt,
    output wire [71:0] wdata,
    output wire        wdata_valid,
    output wire [23:0] pdata1,
    output wire [23:0] pdata2,
    output wire [23:0] pdata3,
    output wire [23:0] pdata4,
    output wire [23:0] pdata5,
    output wire        pdata_valid
//    input  wire        conv_done
);

	localparam IDLE = 2'd0, PARAM_LOAD = 2'd1, IMAGE_LOAD = 2'd2, START_ACCEL = 2'd3;
	localparam SEND_IMAGES_IDLE = 2'd0, SEND_IMAGES_FIRST_ROW = 2'd1, SEND_IMAGES_MIDDLE_ROW = 2'd2, SEND_IMAGES_LAST_ROW = 2'd3;
	localparam IMAGE_ROW = 6'd48;

	///////////////////////////////////////////////////////
	/////////// axi channel

	wire tready;
	wire wr_en;

	assign s_axis_tready = tready;

	assign tready = ((i_state == PARAM_LOAD) | (i_state == IMAGE_LOAD));

	assign wr_en = s_axis_tvalid && tready;

	///////////////////////////////////////////////////////
	/////////// convert state to IDLE
	wire state_convert;
    
	assign o_state_cnvt = state_convert;

//	assign state_convert = ((s_axis_tlast) | (conv_done));
	assign state_convert = (s_axis_tlast);

	///////////////////////////////////////////////////////
	/////////// 

	genvar i,j;

	wire w_ce, w_we;
	wire [23:0] w_idata;
	wire [23:0] w_odata;
	reg w_ce_reg, w_we_reg;
	reg [23:0] w_idata_reg;

	wire b_ce, b_we;
	wire [7:0] b_idata;
	wire [7:0] b_odata;
	reg b_ce_reg, b_we_reg;
	reg [7:0] b_idata_reg;

	wire i_ce[0:IMAGE_ROW-1], i_we[0:IMAGE_ROW-1];
	wire [7:0] i_idata[0:IMAGE_ROW-1];
	wire [7:0] i_odata[0:IMAGE_ROW-1];
	reg i_ce_reg[0:IMAGE_ROW-1], i_we_reg[0:IMAGE_ROW-1];
	reg [7:0] i_idata_reg[0:IMAGE_ROW-1];

	wire [13:0] w_addr;
	reg [13:0] w_addr_reg;
	wire [5:0] i_addr;
	reg [5:0] i_addr_reg;
	reg [3:0] row_cnt;

	assign w_ce = w_ce_reg;
	assign w_we = w_we_reg;
	assign w_idata = w_idata_reg;

	assign b_ce = b_ce_reg;
	assign b_we = b_we_reg;
	assign b_idata = b_idata_reg;

for(i=0; i<IMAGE_ROW; i=i+1) begin
	assign i_ce[i] = i_ce_reg[i];
	assign i_we[i] = i_we_reg[i];
	assign i_idata[i] = i_idata_reg[i];
end

	assign w_addr = w_addr_reg;
	assign i_addr = i_addr_reg;


	bram#(14,24,12672) weights(clk, w_ce, w_we, w_addr, w_idata, w_odata);
	bram#(14,8,129) bias (clk, b_ce, b_we, w_addr, b_idata, b_odata);

for(i=0; i<IMAGE_ROW; i=i+1) begin
		bram#(6,8,48) i_image(clk, i_ce[i], i_we[i], i_addr, i_idata[i], i_odata[i]);
end

	//////////////////////////// weight bram controller
	always@(*) begin
		case(i_state)
			PARAM_LOAD : begin
				if(wr_en) begin
					w_ce_reg = 1'b1;
					w_we_reg = 1'b1;
					w_idata_reg = s_axis_tdata[23:0];
				end
				else begin
					w_ce_reg = 1'b0;
					w_we_reg = 1'b0;
					w_idata_reg = 24'd0;
				end
			end
			START_ACCEL : begin
				w_ce_reg = 1'b1;
				w_we_reg = 1'b0;
				w_idata_reg = 24'd0;
			end
			default : begin
				w_ce_reg = 1'b0;
				w_we_reg = 1'b0;
				w_idata_reg = 24'd0;
			end
		endcase
	end

	//////////////////////////// bias bram controller
	always@(*) begin
		case(i_state)
			PARAM_LOAD : begin
				if((w_addr_reg < 8'd129) & (wr_en)) begin
					b_ce_reg = 1'b1;
					b_we_reg = 1'b1;
					b_idata_reg = s_axis_tdata[31:24];
				end
				else begin
					b_ce_reg = 1'b0;
					b_we_reg = 1'b0;
					b_idata_reg = 8'd0;
				end
			end
			START_ACCEL : begin
				b_ce_reg = 1'b1;
				b_we_reg = 1'b0;
				b_idata_reg = 24'd0;
			end
			default : begin
				b_ce_reg = 1'b0;
				b_we_reg = 1'b0;
				b_idata_reg = 8'd0;
			end
		endcase
	end

	//////////////////////////// input-image bram controller
for (i=0; i<IMAGE_ROW; i=i+1) begin
	always@(*) begin
		case(i_state)
			IMAGE_LOAD : begin
				if(wr_en) begin
					case(row_cnt)
						4'd0 : begin
							if(i<4) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 0) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 1) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 2) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd1 : begin
							if(i>=4 & i<8) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 4) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 5) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 6) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd2 : begin
							if(i>=8 & i<12) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 8) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 9) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 10) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd3 : begin
							if(i>=12 & i<16) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 12) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 13) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 14) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd4 : begin
							if(i>=16 & i<20) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 16) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 17) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 18) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd5 : begin
							if(i>=20 & i<24) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 20) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 21) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 22) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd6 : begin
							if(i>=24 & i<28) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 24) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 25) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 26) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd7 : begin
							if(i>=28 & i<32) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 28) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 29) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 30) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd8 : begin
							if(i>=32 & i<36) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 32) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 33) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 34) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd9 : begin
							if(i>=36 & i<40) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 36) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 37) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 38) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd10 : begin
							if(i>=40 & i<44) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 40) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 41) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 42) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						4'd11 : begin
							if(i>=44 & i<48) begin
								i_ce_reg[i] = 1'b1;
								i_we_reg[i] = 1'b1;
								if(i == 44) i_idata_reg[i] = s_axis_tdata[7:0];
								else if(i == 45) i_idata_reg[i] = s_axis_tdata[15:8];
								else if(i == 46) i_idata_reg[i] = s_axis_tdata[23:16];
								else  i_idata_reg[i] = s_axis_tdata[31:24];
							end
							else begin
								i_ce_reg[i] = 1'b0;
								i_we_reg[i] = 1'b0;
								i_idata_reg[i] = 8'd0;
							end
						end
						default : begin
							i_idata_reg[i] = 8'd0;
						end
					endcase
				end
				else begin
					i_ce_reg[i] = 1'b0;
					i_we_reg[i] = 1'b0;
					i_idata_reg[i] = 8'd0;
				end
			end
			START_ACCEL : begin
				i_ce_reg[i] = 1'b1;
				i_we_reg[i] = 1'b0;
				i_idata_reg[i] = 8'd0;
			end
			default : begin
				i_ce_reg[i] = 1'b0;
				i_we_reg[i] = 1'b0;
				i_idata_reg[i] = 8'd0;
			end
		endcase
	end
end

	//////////////////////////// generate bram address
	reg [5:0] pixel_cnt;

	always@(posedge clk) begin
		if(!rstn) begin
			w_addr_reg <= 14'd0;
			i_addr_reg <= 6'd0;
			row_cnt <= 4'd0;
		end
		else begin
			case(i_state)
				PARAM_LOAD : begin
					if(wr_en) begin
						if(w_addr_reg == 14'd12671) w_addr_reg <= 14'd0;
						else w_addr_reg <= w_addr_reg + 1'b1;
					end
				end
				IMAGE_LOAD : begin
					if(wr_en) begin
						if(i_addr_reg == 6'd47) begin
							i_addr_reg <= 6'd0;
							row_cnt <= row_cnt + 1'b1;
						end
						else i_addr_reg <= i_addr_reg + 1'b1;
					end
				end
				START_ACCEL : begin
					if(w_addr_reg<3) w_addr_reg <= w_addr_reg + 1'b1;
					else begin
						if((pixel_cnt>0) & (pixel_cnt<49)) begin
							if(i_addr_reg == 6'd47) begin
								i_addr_reg <= 6'd0;
							end
							else i_addr_reg <= i_addr_reg + 1'b1;
						end
						else if(pixel_cnt == 49) row_cnt <= row_cnt + 1'b1;	
					end
				end
				default : begin
					w_addr_reg <= 14'd0;
					i_addr_reg <= 6'd0;
					row_cnt <= 4'd0;
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pixel_cnt <= 6'd0;
		end
		else begin
			case(i_state)
				START_ACCEL : begin
					if(w_addr_reg < 3) pixel_cnt <= 6'd0;
					else begin
						if(pixel_cnt == 6'd49) pixel_cnt <= 6'd0;
						else pixel_cnt <= pixel_cnt + 1'b1;
					end
				end
			endcase
		end
	end

	reg [71:0] weight_data;
	reg weight_valid, weight_valid_d;

	assign wdata = weight_data;
	assign wdata_valid = weight_valid_d;

	always@(posedge clk) begin
		if(!rstn) begin
			weight_data <= 72'd0;
		end
		else begin
			case(i_state)
				START_ACCEL : begin
					weight_data <= {weight_data[47:0], w_odata};
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			weight_valid <= 1'b0;
			weight_valid_d <= 1'b0;
		end
		else begin
			weight_valid_d <= weight_valid;
			case(i_state)
				START_ACCEL : begin
					if(w_addr_reg == 14'd2) weight_valid <= 1'b1;
					else weight_valid <= 1'b0;
				end
			endcase
		end
	end

	reg [23:0] pixel_data1, pixel_data2, pixel_data3, pixel_data4, pixel_data5;
	reg pixel_valid, pixel_valid_d;
    reg [1:0] img_state;

	assign pdata1 = pixel_data1;
	assign pdata2 = pixel_data2;
	assign pdata3 = pixel_data3;
	assign pdata4 = pixel_data4;
	assign pdata5 = pixel_data5;
	assign pdata_valid = pixel_valid_d;

	always@(posedge clk) begin
		if(!rstn) begin
			pixel_data1 <= 24'd0;
			pixel_data2 <= 24'd0;
			pixel_data3 <= 24'd0;
			pixel_data4 <= 24'd0;
			pixel_data5 <= 24'd0;
		end
		else begin
			case(i_state)
				START_ACCEL : begin
					case(img_state)
						SEND_IMAGES_FIRST_ROW : begin
							pixel_data1 <= 24'd0;
							if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
								pixel_data2 <= {pixel_data2[15:0], 8'd0};
								pixel_data3 <= {pixel_data3[15:0], 8'd0};
								pixel_data4 <= {pixel_data4[15:0], 8'd0};
								pixel_data5 <= {pixel_data5[15:0], 8'd0};
							end
							else begin
								pixel_data2 <= {pixel_data2[15:0], i_odata[0]};
								pixel_data3 <= {pixel_data3[15:0], i_odata[1]};
								pixel_data4 <= {pixel_data4[15:0], i_odata[2]};
								pixel_data5 <= {pixel_data5[15:0], i_odata[3]};
							end
						end
						SEND_IMAGES_MIDDLE_ROW : begin
							case(row_cnt)
								4'd1 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[2]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[3]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[4]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[5]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[6]};
									end
								end
								4'd2 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[5]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[6]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[7]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[8]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[9]};
									end
								end
								4'd3 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[8]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[9]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[10]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[11]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[12]};
									end
								end
								4'd4 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[11]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[12]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[13]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[14]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[15]};
									end
								end
								4'd5 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[14]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[15]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[16]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[17]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[18]};
									end
								end
								4'd6 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[17]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[18]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[19]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[20]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[21]};
									end
								end
								4'd7 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[20]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[21]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[22]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[23]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[24]};
									end
								end
								4'd8 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[23]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[24]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[25]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[26]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[27]};
									end
								end
								4'd9 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[26]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[27]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[28]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[29]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[30]};
									end
								end
								4'd10 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[29]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[30]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[31]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[32]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[33]};
									end
								end
								4'd11 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[32]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[33]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[34]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[35]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[36]};
									end
								end
								4'd12 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[35]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[36]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[37]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[38]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[39]};
									end
								end
								4'd13 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[38]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[39]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[40]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[41]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[42]};
									end
								end
								4'd14 : begin
									if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
										pixel_data1 <= {pixel_data1[15:0], 8'd0};
										pixel_data2 <= {pixel_data2[15:0], 8'd0};
										pixel_data3 <= {pixel_data3[15:0], 8'd0};
										pixel_data4 <= {pixel_data4[15:0], 8'd0};
										pixel_data5 <= {pixel_data5[15:0], 8'd0};
									end
									else begin
										pixel_data1 <= {pixel_data1[15:0], i_odata[41]};
										pixel_data2 <= {pixel_data2[15:0], i_odata[42]};
										pixel_data3 <= {pixel_data3[15:0], i_odata[43]};
										pixel_data4 <= {pixel_data4[15:0], i_odata[44]};
										pixel_data5 <= {pixel_data5[15:0], i_odata[45]};
									end
								end
							endcase
						end
						SEND_IMAGES_LAST_ROW : begin
							pixel_data5 <= 24'd0;
							if((pixel_cnt == 0) | (pixel_cnt == 49)) begin
								pixel_data1 <= {pixel_data1[15:0], 8'd0};
								pixel_data2 <= {pixel_data2[15:0], 8'd0};
								pixel_data3 <= {pixel_data3[15:0], 8'd0};
								pixel_data4 <= {pixel_data4[15:0], 8'd0};
							end
							else begin
								pixel_data1 <= {pixel_data1[15:0], i_odata[44]};
								pixel_data2 <= {pixel_data2[15:0], i_odata[45]};
								pixel_data3 <= {pixel_data3[15:0], i_odata[46]};
								pixel_data4 <= {pixel_data4[15:0], i_odata[47]};
							end
							
						end
					endcase
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pixel_valid <= 1'b0;
			pixel_valid_d <= 1'b0;
		end
		else begin
			pixel_valid_d <= pixel_valid;
			case(i_state)
				START_ACCEL : begin
					if(img_state != SEND_IMAGES_IDLE) begin
						if((pixel_cnt > 0) & (pixel_cnt < 49)) pixel_valid <= 1'b1;
						else pixel_valid <= 1'b0;
					end
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			img_state <= SEND_IMAGES_IDLE;
		end
		else begin
			case(img_state)
				SEND_IMAGES_IDLE : if((i_state == START_ACCEL) & (w_addr_reg == 3)) img_state <= SEND_IMAGES_FIRST_ROW;
				SEND_IMAGES_FIRST_ROW : if(pixel_cnt == 49) img_state <= SEND_IMAGES_MIDDLE_ROW;
				SEND_IMAGES_MIDDLE_ROW : if((pixel_cnt == 49) & (row_cnt == 14)) img_state <= SEND_IMAGES_LAST_ROW;
				SEND_IMAGES_LAST_ROW : if(pixel_cnt == 49) img_state <= SEND_IMAGES_IDLE;
			endcase
		end
	end

endmodule
