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
    output wire        o_load_state,
    output wire [1:0]  o_current_layer,
    input  wire        i_last           //////////////////////// assign m_axis_tlast
);

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

	reg load_state;
	reg [1:0] current_layer;

	assign o_load_state = load_state;
	assign o_current_layer = current_layer;

	always@(posedge clk) begin
		if(!rstn) begin
			load_state <= 1'b0;
			current_layer <= 2'd0;
		end
		else begin
			if(wr_en) begin
				case(awaddr[3:2])
					2'b00 : begin
							if(s_axi_wdata[0]) begin
								{current_layer, load_state} <= s_axi_wdata[3:1];
								
							end
						end
					default : begin
							load_state <= 1'b0;
							current_layer <= 2'd0;
						end
				endcase
			end
		end
	end

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

	// dont use the read channel.
	assign s_axi_arready = 1'b0;
	assign s_axi_rvalid = 1'b0;
	assign s_axi_rdata = 32'hDEADBEEF;
	assign s_axi_rresp = 2'b00;


endmodule
