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

);

    genvar i, j;
    
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
	
	assign i_pe_img[0] = i_pe_1_row;
	assign i_pe_img[1] = i_pe_2_row;
	assign i_pe_img[2] = i_pe_3_row;
	assign i_pe_img[3] = i_pe_4_row;
	assign i_pe_img[4] = i_pe_5_row;
 
 ////////////////////////////////////// operate conv with signed w_reg.
 
     for(j = 0; j<3; j=j+1) begin: pe_gen
 	   pe pe_1(clk, rstn, w_reg[71:64], w_reg[63:56], w_reg[55:48], i_pe_img[j], i_pe_valid, o_pe_1[j], o_pe_11_valid);
	   pe pe_2(clk, rstn, w_reg[47:40], w_reg[39:32], w_reg[31:24], i_pe_img[j+1], i_pe_valid, o_pe_2[j], o_pe_12_valid);
	   pe pe_3(clk, rstn, w_reg[23:16], w_reg[15:8], w_reg[7:0], i_pe_img[j+2], i_pe_valid, o_pe_3[j], o_pe_13_valid);
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
