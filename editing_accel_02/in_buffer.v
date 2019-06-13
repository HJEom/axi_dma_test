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
    output wire        o_state_cnvt
    input  wire        conv_done
);

	localparam IDLE = 2'd0, PARAM_LOAD = 2'd1, IMAGE_LOAD = 2'd2, START_ACCEL = 2'd3;
	localparam IMAGE_ROW = 6'd48;

	///////////////////////////////////////////////////////
	/////////// axi channel

	wire tready;
	wire wr_en;

	assign s_axis_tready = tready;

	assign tready = ((i_state == PARAM_LOAD) & (i_state == IMAGE_LOAD));

	assign wr_en = s_axis_tvalid && tready;

	///////////////////////////////////////////////////////
	/////////// convert state to IDLE
	wire state_convert;
    
	assign o_state_cnvt = state_convert;

	assign state_convert = ((s_axis_tlast) | (conv_done));
	///////////////////////////////////////////////////////
	/////////// 

	genvar i;
	reg w_ce, b_ce, i_ce[0:IMAGE_ROW-1];
	reg w_we, b_we, i_we;

	reg [23:0] w_idata, b_idata;
	wire [7:0]  w_odata, b_odata;
	reg [7:0]  i_idata[0:IMAGE_ROW-1];
	wire [7:0]  i_odata[0:IMAGE_ROW-1];
	reg [13:0] addr;

	bram#(14, 24, 12672) weights(clk, w_ce, w_we, addr, w_idata, w_odata);
	bram#(8, 8, 129)     bias   (clk, b_ce, b_we, addr, b_idata, b_odata);

	for(i=0; i<IMAGE_ROW; i=i+1) begin
		bram#(6, 8, IMAGE_ROW) i_image(clk, i_ce[i], i_we, addr, i_idata[i], i_odata[i]);
	end

	always@(*) begin
		case(i_state)
			PARAM_LOAD : begin
				if(wr_en) begin
					w_ce = 1'b1;
					w_we = 1'b1;
					w_idata = s_axis_tdata[23:0];
				end
				else begin
					w_ce = 1'b0;
					w_we = 1'b0;
					w_idata = 24'd0;
				end
			end
			default : begin
				w_ce = 1'b0;
				w_we = 1'b0;
				w_idata = 24'd0;
			end
		endcase
	end

	always@(*) begin
		case(i_state)
			PARAM_LOAD : begin
				if((addr < 8'd129) & (wr_en)) begin
					b_ce = 1'b1;
					b_we = 1'b1;
					b_idata = s_axis_tdata[31:24];
				end
				else begin
					b_ce = 1'b0;
					b_we = 1'b0;
					b_idata = 8'd0;
				end
			end
			default : begin
				b_ce = 1'b0;
				b_we = 1'b0;
				b_idata = 8'd0;
			end
		endcase
	end

	always@(posedge clk) begin
		if(!rstn) begin
			addr <= 14'd0;
		end
		else begin
			case(i_state)
				PARAM_LOAD : begin
					if(wr_en) begin
						if(addr == 14'd12671) addr <= 14'd0;
						else addr <= addr + 1'b1;
					end
				end
				default : addr <= 14'd0;
			endcase
		end
	end



endmodule
