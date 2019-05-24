`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/20 14:36:32
// Design Name: 
// Module Name: s_axi
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


module s_axi(
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
    output wire        out_valid,
    output wire [71:0] out_data
);

	///////////////////////////////////////////////////////
	/////////// write channel
	reg [31:0] awaddr;
	reg awready;
	reg wready;
	reg [1:0] bresp;
	reg bvalid;
	reg aw_en;

	reg [71:0] weights;    // 24-bit * 3 = 72-bit that is the number of kernel elements as each 8-bit
	reg weights_valid;
	wire weights_wren;
	(* ram_style = "{block}" *)
	reg [23:0] fifo[0:130000];
	reg [17:0] wr_ptr;
	reg [17:0] rd_ptr;
    reg send_w;
    
	assign s_axi_awready = awready;
	assign s_axi_wready = wready;
	assign s_axi_bresp = bresp;
	assign s_axi_bvalid = bvalid;
	assign out_data = weights;
	assign out_valid = weights_valid;

	always@(posedge clk) begin
		if(weights_wren) fifo[wr_ptr] = s_axi_wdata[23:0];
	end

	always@(posedge clk) begin
		if(!rstn) begin
			wr_ptr <= 18'd0;
		end
		else begin
			if(weights_wren) wr_ptr <= wr_ptr + 1'b1;
			else if(wr_ptr == 18'd130000) wr_ptr <= 18'd0;
		end
	end
	
	always@(posedge clk) begin
		if(!rstn) begin
			rd_ptr <= 18'd0;
		end
		else begin
			if(send_w) rd_ptr <= rd_ptr + 1'b1;
			else rd_ptr <= 18'd0;
		end
	end

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

	assign weights_wren = wready && s_axi_wvalid && awready && s_axi_awvalid;

	always@(posedge clk) begin
		if(!rstn) begin
			weights <= 72'd0;
			weights_valid <= 1'b0;
			send_w <= 1'b0;
		end
		else begin
			if(weights_wren) begin
				case(awaddr[3:2])
					2'b00 : begin
							send_w <= 1'b1;
							weights <= {weights[47:0], fifo[rd_ptr]};
							weights_valid <= 1'b0;
						end
					2'b01 : begin
							weights <= {weights[47:0], fifo[rd_ptr]};
							weights_valid <= 1'b0;
						end
					2'b10 : begin 
							weights <= {weights[47:0], fifo[rd_ptr]};
							weights_valid <= 1'b1;
						end
					default : begin
							weights_valid <= 1'b0;
							send_w <= 1'b0;
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

	assign s_axi_arready = 1'b0;
	assign s_axi_rvalid = 1'b0;
	assign s_axi_rdata = 32'hDEADBEEF;
	assign s_axi_rresp = 2'b00;


endmodule
