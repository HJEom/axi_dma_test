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
    input  wire [71:0] wdata,
    input  wire        wdata_valid,
    input  wire [23:0] pdata1,
    input  wire [23:0] pdata2,
    input  wire [23:0] pdata3,
    input  wire [23:0] pdata4,
    input  wire [23:0] pdata5,
    input  wire        pdata_valid
);

	localparam IMAGE_ROW = 48;
	localparam SEND_IMAGE = 1;
	genvar i, j;
    
	reg c_state;
	reg [71:0] w_reg;
	always@(posedge clk) begin
		if(!rstn) begin
			w_reg <= 72'd0;
		end
		else begin
			if(wdata_valid) begin
				w_reg <= wdata;
			end
		end
	end
	
	wire [23:0] i_pe_px[0:5-1];
	wire i_pe_valid;
	wire signed [10:0] o_pe_1[0:3-1];
	wire signed [10:0] o_pe_2[0:3-1];
	wire signed [10:0] o_pe_3[0:3-1];
	wire o_pe_1_valid, o_pe_2_valid, o_pe_3_valid;
	wire [7:0] o_pe_sum_[0:3-1];

	assign i_pe_px[0] = pdata1;
	assign i_pe_px[1] = pdata2;
	assign i_pe_px[2] = pdata3;
	assign i_pe_px[3] = pdata4;
	assign i_pe_px[4] = pdata5;
	assign i_pe_valid = pdata_valid;
 
 ////////////////////////////////////// operate conv with signed w_reg.
 
for(j = 0; j<3; j=j+1) begin: pe_gen
	pe pe_1(clk, rstn, w_reg[71:64], w_reg[63:56], w_reg[55:48], i_pe_px[j], i_pe_valid, o_pe_1[j], o_pe_1_valid);
	pe pe_2(clk, rstn, w_reg[47:40], w_reg[39:32], w_reg[31:24], i_pe_px[j+1], i_pe_valid, o_pe_2[j], o_pe_2_valid);
	pe pe_3(clk, rstn, w_reg[23:16], w_reg[15:8], w_reg[7:0], i_pe_px[j+2], i_pe_valid, o_pe_3[j], o_pe_3_valid);
	manage_overflow mof(o_pe_1[j], o_pe_2[j], o_pe_3[j], o_pe_1_valid, o_pe_sum_[j]);
end

    wire o_ce[0:IMAGE_ROW-1];
    wire o_we[0:IMAGE_ROW-1];
    wire [5:0] o_addr;
    wire [7:0] o_idata[0:IMAGE_ROW-1],o_odata[0:IMAGE_ROW-1];
    
    reg o_ce_reg[0:IMAGE_ROW-1];
    reg o_we_reg[0:IMAGE_ROW-1];
    reg [5:0] o_addr_reg;
    reg [7:0] o_idata_reg[0:IMAGE_ROW-1];
    
for(i=0;i<IMAGE_ROW;i=i+1) begin
    assign o_ce[i] = o_ce_reg[i];
    assign o_we[i] = o_we_reg[i];
    assign o_idata[i] = o_idata_reg[i];
end

assign o_addr = o_addr_reg;

for(i=0; i<IMAGE_ROW; i=i+1) begin
	bram#(6, 8, 48) o_image(clk, o_ce[i], o_we[i], o_addr, o_idata[i], o_odata[i]);
end

for(i=0; i<IMAGE_ROW; i=i+1) begin
	always@(*) begin
		if(o_pe_1_valid) begin
			case(o_row_cnt)
				4'd0 : begin
					if(i<3) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd1 : begin
					if(i>=3 & i<6) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd2 : begin
					if(i>=6 & i<9) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd3 : begin
					if(i>=9 & i<12) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd4 : begin
					if(i>=12 & i<15) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd5 : begin
					if(i>=15 & i<18) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd6 : begin
					if(i>=18 & i<21) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd7 : begin
					if(i>=21 & i<24) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd8 : begin
					if(i>=24 & i<27) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd9 : begin
					if(i>=27 & i<30) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd10 : begin
					if(i>=30 & i<33) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd11 : begin
					if(i>=33 & i<36) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd12 : begin
					if(i>=36 & i<39) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd13 : begin
					if(i>=39 & i<42) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd14 : begin
					if(i>=42 & i<45) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
				4'd15 : begin
					if(i>=45 & i<48) begin
						o_ce_reg[i] = 1'b1;
						o_we_reg[i] = 1'b1;
						o_idata_reg[i] = o_pe_sum_[i%3];
					end
					else begin
						o_ce_reg[i] = 1'b0;
						o_we_reg[i] = 1'b0;
						o_idata_reg[i] = 8'd0;
					end
				end
			endcase
		end
		else if(c_state == SEND_IMAGE) begin
			o_ce_reg[i] = 1'b1;
			o_we_reg[i] = 1'b0;
			o_idata_reg[i] = 8'd0;
		end
		else begin
			o_ce_reg[i] = 1'b0;
			o_we_reg[i] = 1'b0;
			o_idata_reg[i] = 8'd0;
		end
	end
end

	always@(posedge clk) begin
		if(!rstn) begin
			o_addr_reg <= 6'd0;
		end
		else begin
			case(c_state)
				1'b0: begin
					if(o_pe_1_valid) begin
						if(px_cnt == 47) o_addr_reg <= 6'd0;
						else o_addr_reg <= o_addr_reg + 1'b1;
					end
					else if(px_cnt == 47) begin
						o_addr_reg <= 6'd0;
						if(o_row_cnt == 15) o_row_cnt <= 4'd0;
						else o_row_cnt <= o_row_cnt + 1'b1;
					end
				end
				SEND_IMAGE : begin
					if(px_cnt == 47) o_addr_reg <= 6'd0;
					else o_addr_reg <= o_addr_reg + 1'b1;
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			px_cnt_d <= 6'd0;
			px_cnt_dd <= 6'd0;
		end
		else begin
			case(c_state)
				1'b0 : begin
					px_cnt_dd <= 6'd0;
				end
				SEND_IMAGE : begin
					px_cnt_d <= px_cnt;
					px_cnt_dd <= px_cnt_d;
				end
			endcase
		end
	end

	reg [5:0] px_cnt, px_cnt_d, px_cnt_dd;
	reg [3:0] o_row_cnt;
	always@(posedge clk) begin
		if(!rstn) begin
			px_cnt <= 6'd0;
			o_row_cnt <= 4'd0;
		end
		else begin
			case(c_state)
				1'b0: begin
					if(o_pe_1_valid) begin
						if(px_cnt == 47) begin
							px_cnt <= 6'd0;
							if(o_row_cnt == 15) o_row_cnt <= 4'd0;
							else o_row_cnt <= o_row_cnt + 1'b1;
						end
						else begin
							px_cnt <= px_cnt + 1'b1;
						end
					end
					else if(px_cnt == 47) begin
						px_cnt <= 6'd0;
						if(o_row_cnt == 15) o_row_cnt <= 4'd0;
						else o_row_cnt <= o_row_cnt + 1'b1;
					end
				end
				SEND_IMAGE : begin
					if(px_cnt == 47) begin
						px_cnt <= 6'd0;
					end
					else begin
						px_cnt <= px_cnt + 1'b1;
					end
					if(px_cnt_dd == 47) begin
						if(o_row_cnt == 11) o_row_cnt <= 4'd0;
						else o_row_cnt <= o_row_cnt + 1'b1;
					end
				end
			endcase
		end
	end

	reg tvalid, tvalid_d;
	reg tlast;
	reg [31:0] tdata;

	always@(posedge clk) begin
		if(!rstn) begin
			c_state <= 1'b0;
		end
		else begin
			case(c_state)
				1'b0 : begin
					if((o_row_cnt == 15) & ( px_cnt == 47)) c_state <= SEND_IMAGE;
				end
				SEND_IMAGE : if((o_row_cnt == 11) & (px_cnt_dd == 47)) c_state <= 1'b0;
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			tvalid <= 1'b0;
			tvalid_d <= 1'b0;
		end
		else begin
			tvalid_d <= tvalid;
			case(c_state)
				1'b0 : begin
					tvalid <= 1'b0;
				end
				SEND_IMAGE : begin
					if((o_row_cnt == 0) & (px_cnt == 1)) tvalid <= 1'b1;
					else if((o_row_cnt == 11) & (px_cnt_dd == 47)) tvalid <= 1'b0;
				end
			endcase
		end
	end


	always@(posedge clk) begin
		if(!rstn) begin	
			tdata <= 32'd0;
		end
		else begin
			case(c_state)
				SEND_IMAGE: begin
					case(o_row_cnt)
						4'd0: tdata <= {o_odata[3], o_odata[2], o_odata[1], o_odata[0]};
						4'd1: tdata <= {o_odata[7], o_odata[6], o_odata[5], o_odata[4]};
						4'd2: tdata <= {o_odata[11], o_odata[10], o_odata[9], o_odata[8]};
						4'd3: tdata <= {o_odata[15], o_odata[14], o_odata[13], o_odata[12]};
						4'd4: tdata <= {o_odata[19], o_odata[18], o_odata[17], o_odata[16]};
						4'd5: tdata <= {o_odata[23], o_odata[22], o_odata[21], o_odata[20]};
						4'd6: tdata <= {o_odata[27], o_odata[26], o_odata[25], o_odata[24]};
						4'd7: tdata <= {o_odata[31], o_odata[30], o_odata[29], o_odata[28]};
						4'd8: tdata <= {o_odata[35], o_odata[34], o_odata[33], o_odata[32]};
						4'd9: tdata <= {o_odata[39], o_odata[38], o_odata[37], o_odata[36]};
						4'd10: tdata <= {o_odata[43], o_odata[42], o_odata[41], o_odata[40]};
						4'd11: tdata <= {o_odata[47], o_odata[46], o_odata[45], o_odata[44]};
					endcase
				end
			endcase
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			tlast <= 1'b0;
		end
		else begin
			case(c_state)
				SEND_IMAGE : begin
					case(o_row_cnt)
						4'd11: begin
							if(px_cnt_dd == 46) tlast <= 1'b1;
							else tlast <= 1'b0;
						end
						default : tlast <= 1'b0;
					endcase
				end
			default : tlast <= 1'b0;
			endcase
		end
	end
	
	assign m_axis_tvalid = tvalid;
	assign m_axis_tlast = tlast;
	assign m_axis_tdata = tdata;
	assign m_axis_tstrb = 4'b1111;

endmodule
