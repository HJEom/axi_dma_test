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
    output wire [1:0]  o_current_layer,
    output wire [5:0]  o_current_ic,
    output wire [5:0]  o_current_oc,
    output wire        o_valid,
    output wire [79:0] bais_weights,
    output wire        bais_weights_valid
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

	reg [1:0] c_state, c_layer;
	reg [5:0] c_ic, c_oc;
	reg state_valid;
	reg [79:0] params;
	reg params_valid_d;
	wire params_valid_dd;

	assign o_state = c_state;
	assign o_current_layer = c_layer;
	assign o_current_ic = c_ic;
	assign o_current_oc = c_oc;
	assign o_valid = state_valid;
	assign bais_weights = params;
	assign bais_weights_valid = params_valid_d;

	always@(posedge clk) begin
		if(!rstn) begin
			c_state <= 2'd0;
			c_layer <= 2'd0;
			c_ic <= 6'd0;
			c_oc <= 6'd0;
			state_valid <= 1'b0;
			params <= 80'd0;
		end
		else begin
			if(wr_en) begin
				case(awaddr[3:2])
					2'b00 : begin
						{c_oc, c_ic, c_layer, c_state, state_valid} <= s_axi_wdata[16:0];
					end
					2'b01 : params <= {{(48){1'b0}}, s_axi_wdata};
					2'b10 : params <= {params[55:0], s_axi_wdata[23:0]};
					2'b11 : params <= {params[55:0], s_axi_wdata[23:0]};
					default : begin
						c_state <= 2'd0;
						c_layer <= 2'd0;
						c_ic <= 6'd0;
						c_oc <= 6'd0;
						state_valid <= 1'b0;
						params <= 80'd0;
					end
				endcase
			end
		end
	end

	assign params_valid_dd = ((wr_en) && (awaddr[3:2] == 2'b11)) ? 1'b1 : 1'b0;
	always@(posedge clk) begin
		if(!rstn) begin
			params_valid_d <= 1'b0;
		end
		else begin
			params_valid_d <= params_valid_dd;
		end
	end

endmodule
