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
    input  wire [1:0]  i_current_layer,
    input  wire [5:0]  i_current_ic,
    input  wire [5:0]  i_current_oc,
    input  wire        i_valid,
    output wire [23:0] o_pe_1_row,
    output wire [23:0] o_pe_2_row,
    output wire [23:0] o_pe_3_row,
    output wire [23:0] o_pe_4_row,
    output wire [23:0] o_pe_5_row,
    output wire        o_pe_valid,
    output wire        img_row_done,
    output             send_flg
);

	localparam IDLE = 2'd0,
			IMAGES_LOAD = 2'd1,
			SEND_DATA = 2'd2;

	localparam SEND_IMAGES_IDLE = 3'd0,
	        SEND_IMAGES_FIRST_ROW = 3'd1,
			SEND_IMAGES_MIDDLE_ROW = 3'd2,
			SEND_IMAGES_LAST_ROW = 3'd3;

	localparam IMAGES_NUMBER = 2304;

	wire tready;
	wire wr_en;

	assign s_axis_tready = tready;

	reg [1:0] c_state;

	reg img_ce, img_we, tlast_d, tlast_dd;
	reg [31:0] i_img;
	reg [11:0] img_addr, img_addr_;
	wire [39:0] o_img;

	reg [5:0] pixel_cnt;
	reg [5:0] row_cnt;

	reg [1:0] img_state;
	reg [23:0] pe_1_reg;
	reg [23:0] pe_2_reg;
	reg [23:0] pe_3_reg;
	reg [23:0] pe_4_reg;
	reg [23:0] pe_5_reg;
	reg pe_valid;

	assign o_pe_1_row = pe_1_reg;
	assign o_pe_2_row = pe_2_reg;
	assign o_pe_3_row = pe_3_reg;
	assign o_pe_4_row = pe_4_reg;
	assign o_pe_5_row = pe_5_reg;
	assign o_pe_valid = pe_valid;

	reg [5:0] ic;
	reg send2dma;

	always@(posedge clk) begin
		if(!rstn) begin
			c_state <= IDLE;
		end
		else begin
			case(c_state)
				IDLE : begin
					if(s_axis_tvalid) begin
						case(i_state)
							2'd1 : c_state <= IMAGES_LOAD;
						endcase
					end
				end
				IMAGES_LOAD : begin
					if(tlast_d) c_state <= SEND_DATA;
				end
				SEND_DATA : begin
					if(send2dma) c_state <= IDLE; //////////////////////////////////////////////////////////////////////////conv done is 	
				end
			endcase
		end
	end
    always@(posedge clk) begin
        if(!rstn) begin
            tlast_d <= 1'b0;
            tlast_dd <= 1'b0;
        end
        else begin
            tlast_d <= s_axis_tlast;
            tlast_dd <= tlast_d;
        end
    end
	assign tready = (c_state == IMAGES_LOAD);

	assign wr_en = s_axis_tvalid && tready;

	fifo#(8,2304) img_buffer(clk, rstn, img_ce, img_we, img_addr_, i_img, o_img);
	
	always@(posedge clk) begin
        if(!rstn) begin
            img_addr <= 12'd0;
        end
        else begin
            case(c_state)
                IMAGES_LOAD : begin
                    if(wr_en) begin
                        if(img_addr == 12'd2300) img_addr <= 12'd0;
                        else img_addr <= img_addr + 3'd4;
                    end
                end
                default : img_addr <= 12'd0;
            endcase
        end
    end
    
    always@(*) begin
         case(c_state)
        IMAGES_LOAD : img_addr_ = img_addr;
        SEND_DATA : begin
        if((img_state != SEND_IMAGES_IDLE) && (pixel_cnt < 49) && (pixel_cnt > 0)) begin
            img_addr_ = (pixel_cnt-1) + row_cnt*96;
        end
        else img_addr_ = 0;
        end
        default : img_addr_ = 12'd0;
    endcase
    end
    
	always@(*) begin
			case(c_state)
				IMAGES_LOAD : begin
					if(wr_en) begin
						img_ce = 1'b1;
						img_we = 1'b1;
						i_img = s_axis_tdata;
					end
					else begin
					   img_ce = 1'b0;
					   img_we = 1'b0;
					   i_img = s_axis_tdata;
					   end
				end
				SEND_DATA : begin
				    if(!(img_state == SEND_IMAGES_IDLE)) begin
					   img_ce = 1'b1;
					   img_we = 1'b0;
					end
				end
				default : begin
				    img_ce = 1'b0;
                                       img_we = 1'b0;
                                       i_img = s_axis_tdata;
                                       end
			endcase
		end

	always@(posedge clk) begin
		if(!rstn) begin
			pixel_cnt <= 6'd0;
			row_cnt <= 6'd0;
		end
		else begin
			case(c_state)
				SEND_DATA : begin
				    if(img_state != SEND_IMAGES_IDLE) begin
    					if(pixel_cnt == 6'd49) begin
    						pixel_cnt <= 6'd0;
    						if(row_cnt == 6'd15) row_cnt <= 6'd0;
    						else row_cnt <= row_cnt + 1'b1;
					   end
					   else pixel_cnt <= pixel_cnt + 1'b1;
					end
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			pe_1_reg <= 24'd0;
			pe_2_reg <= 24'd0;
			pe_3_reg <= 24'd0;
			pe_4_reg <= 24'd0;
			pe_5_reg <= 24'd0;
		end
		else begin
			if((c_state == SEND_DATA) && (img_state == SEND_IMAGES_FIRST_ROW)) begin
				if((pixel_cnt == 6'd48) || (pixel_cnt == 6'd49))begin		
					pe_1_reg <= 24'd0;
					pe_2_reg <= {pe_2_reg[15:0], 8'd0};
					pe_3_reg <= {pe_3_reg[15:0], 8'd0};
					pe_4_reg <= {pe_4_reg[15:0], 8'd0};
					pe_5_reg <= {pe_5_reg[15:0], 8'd0};
				end	
				else begin		
					pe_1_reg <= 24'd0;
					pe_2_reg <= {pe_2_reg[15:0], o_img[39:32]};
					pe_3_reg <= {pe_3_reg[15:0], o_img[31:24]};
					pe_4_reg <= {pe_4_reg[15:0], o_img[23:16]};
					pe_5_reg <= {pe_5_reg[15:0], o_img[15:8]};
				end
			end
			else if((c_state == SEND_DATA) && (img_state == SEND_IMAGES_MIDDLE_ROW)) begin
				if((pixel_cnt == 6'd48) || (pixel_cnt == 6'd49))begin		
					pe_1_reg <= {pe_1_reg[15:0], 8'd0};
					pe_2_reg <= {pe_2_reg[15:0], 8'd0};
					pe_3_reg <= {pe_3_reg[15:0], 8'd0};
					pe_4_reg <= {pe_4_reg[15:0], 8'd0};
					pe_5_reg <= {pe_5_reg[15:0], 8'd0};
				end	
				else begin		
					pe_1_reg <= {pe_1_reg[15:0], o_img[39:32]};
					pe_2_reg <= {pe_2_reg[15:0], o_img[31:24]};
					pe_3_reg <= {pe_3_reg[15:0], o_img[23:16]};
					pe_4_reg <= {pe_4_reg[15:0], o_img[15:8]};
					pe_5_reg <= {pe_5_reg[15:0], o_img[7:0]};
				end
			end
			else if((c_state == SEND_DATA) && (img_state == SEND_IMAGES_LAST_ROW)) begin
				if((pixel_cnt == 6'd48)) begin		
					pe_1_reg <= {pe_1_reg[15:0], 8'd0};
					pe_2_reg <= {pe_2_reg[15:0], 8'd0};
					pe_3_reg <= {pe_3_reg[15:0], 8'd0};
					pe_4_reg <= {pe_4_reg[15:0], 8'd0};
					pe_5_reg <= 24'd0;
				end	
				else begin		
					pe_1_reg <= {pe_1_reg[15:0], o_img[39:32]};
					pe_2_reg <= {pe_2_reg[15:0], o_img[31:24]};
					pe_3_reg <= {pe_3_reg[15:0], o_img[23:16]};
					pe_4_reg <= {pe_4_reg[15:0], o_img[15:8]};
					pe_5_reg <= 24'd0;
				end
			end
		end
	end

	always@(*) begin
			if((c_state == SEND_DATA) && (pixel_cnt > 6'd1)) pe_valid = 1'b1;
			else pe_valid = 1'b0;
	end

	always@(posedge clk) begin
		if(!rstn) begin
			img_state <= SEND_IMAGES_IDLE;
		end
		else begin
			case(img_state)
			    SEND_IMAGES_IDLE : if(c_state == SEND_DATA) img_state <= SEND_IMAGES_FIRST_ROW;
				SEND_IMAGES_FIRST_ROW : if((row_cnt == 6'd0) && (pixel_cnt == 6'd49)) img_state <= SEND_IMAGES_MIDDLE_ROW;
				SEND_IMAGES_MIDDLE_ROW : if((row_cnt == 6'd14) && (pixel_cnt == 6'd49)) img_state <= SEND_IMAGES_LAST_ROW;
				SEND_IMAGES_LAST_ROW : if((row_cnt == 6'd15) && (pixel_cnt == 6'd49)) img_state <= SEND_IMAGES_IDLE;
			endcase
		end
	end

	assign img_row_done = (pixel_cnt == 6'd49) ? 1'b1 : 1'b0;

	always@(posedge clk) begin
		if(!rstn) begin
			ic <= 6'd0;
		end
		else begin
			case(i_current_layer)
				2'd0 : ic <= 6'd0;
				2'd1 : ic <= 6'd63;
				2'd2 : ic <= 6'd63;
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			send2dma <= 1'b0;
		end
		else begin
			if((i_current_ic == ic) && (row_cnt == 6'd15) && (pixel_cnt == 6'd49)) send2dma <= 1'b1;
			else send2dma <= 1'b0;
		end
	end

	assign send_flg = send2dma;

endmodule
