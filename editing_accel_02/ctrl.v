`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: ctrl
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


module ctrl(
    input  wire        clk,
    input  wire        rstn,
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [3:0]  s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    output wire [1:0]  o_state,
    input  wire        i_state_cnvt
);

	localparam IDLE = 2'd0, PARAM_LOAD = 2'd1, IMAGE_LOAD = 2'd2, START_ACCEL = 2'd3;

	///////////////////////////////////////////////////////
	/////////// write channel
	reg [31:0] awaddr;
	reg awready;
	reg wready;
	reg [1:0] bresp;
	reg bvalid;
	reg aw_en;
	wire wr_en;

	assign s_axi_awready = awready;
	assign s_axi_wready = wready;
	assign s_axi_bresp = bresp;
	assign s_axi_bvalid = bvalid;

	always@(posedge clk) begin
		if(!rstn) begin
			awready <= 1'b0;
			aw_en <= 1'b0;
		end
		else begin
			if(!awready && s_axi_awvalid && s_axi_wvalid && !aw_en) begin
				awready <= 1'b1;
				aw_en <= 1'b1;
			end
			else if(s_axi_bready && bvalid) begin
				awready <= 1'b0;
				aw_en <= 1'b0;
			end
			else begin
				awready <= 1'b0;
			end
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			awaddr <= 32'd0;
		end
		else begin
			if(!awready && s_axi_awvalid && s_axi_wvalid && !aw_en) begin
				awaddr <= s_axi_awaddr;
			end
		end
	end

	always@(posedge clk) begin
		if(!rstn) begin
			wready <= 1'b0;
		end
		else begin
			if(!wready && s_axi_wvalid && s_axi_awvalid && !aw_en) begin
				wready <= 1'b1;
			end
			else begin
				wready <= 1'b0;
			end
		end
	end

	assign wr_en = wready && s_axi_wvalid && awready && s_axi_awvalid;

	always@(posedge clk) begin
		if(!rstn) begin
			bvalid <= 1'b0;
			bresp <= 2'd0;
		end
		else begin
			if(awready && s_axi_awvalid && !bvalid && wready && s_axi_wvalid) begin
				bvalid <= 1'b1;
				bresp <= 2'd0;
			end
			else begin
				if(s_axi_bready && bvalid) begin
					bvalid <= 1'b0;
				end
			end
		end
	end

	///////////////////////////////////////////////////////
	/////////// dont use the read channel.
	assign s_axi_arready = 1'b0;
	assign s_axi_rvalid = 1'b0;
	assign s_axi_rdata = 32'hDEADBEEF;
	assign s_axi_rresp = 2'b00;

	///////////////////////////////////////////////////////
	/////////// receive wdata

	reg [1:0] c_state;

	assign o_state = c_state;

	always@(posedge clk) begin
		if(!rstn) begin
			c_state <= IDLE;
		end
		else begin
			if(wr_en) begin
				case(awaddr[3:2])
					2'b00 : begin
						if((c_state == IDLE) & (s_axi_wdata[1:0] == 2'b01)) begin
							c_state <= PARAM_LOAD;
						end
						else if((c_state == IDLE) & (s_axi_wdata[1:0] == 2'b10)) begin
							c_state <= IMAGE_LOAD;
						end
					end
					default : c_state <= 2'd0;
				endcase
			end
			else begin
				if(i_state_cnvt) begin
					c_state <= IDLE;
				end
			end
		end
	end

endmodule
