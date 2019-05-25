
`timescale 1 ns / 1 ps

    	module top
	(
		output wire [3:0] leds,
		// Ports of Axi Slave Bus Interface S_AXI
		input wire  s_axi_aclk,
		input wire  s_axi_aresetn,
		input wire [32-1 : 0] s_axi_awaddr,
		input wire [2 : 0] s_axi_awprot,
		input wire  s_axi_awvalid,
		output wire  s_axi_awready,
		input wire [32-1 : 0] s_axi_wdata,
		input wire [(32/8)-1 : 0] s_axi_wstrb,
		input wire  s_axi_wvalid,
		output wire  s_axi_wready,
		output wire [1 : 0] s_axi_bresp,
		output wire  s_axi_bvalid,
		input wire  s_axi_bready,
		input wire [4-1 : 0] s_axi_araddr,
		input wire [2 : 0] s_axi_arprot,
		input wire  s_axi_arvalid,
		output wire  s_axi_arready,
		output wire [32-1 : 0] s_axi_rdata,
		output wire [1 : 0] s_axi_rresp,
		output wire  s_axi_rvalid,
		input wire  s_axi_rready,

		// Ports of Axi Master Bus Interface M_AXIS
		input wire  m_axis_aclk,
		input wire  m_axis_aresetn,
		output wire  m_axis_tvalid,
		output wire [32-1 : 0] m_axis_tdata,
		output wire [(32/8)-1 : 0] m_axis_tstrb,
		output wire  m_axis_tlast,
		input wire  m_axis_tready,

		// Ports of Axi Slave Bus Interface S_AXIS
		input wire  s_axis_aclk,
		input wire  s_axis_aresetn,
		output wire  s_axis_tready,
		input wire [32-1 : 0] s_axis_tdata,
		input wire [(32/8)-1 : 0] s_axis_tstrb,
		input wire  s_axis_tlast,
		input wire  s_axis_tvalid
	);

	wire ctrl_o_state, ctrl_i_last;
	wire [1:0] ctrl_o_layer;
	wire in_buffer_i_state, in_buffer_i_valid;
	wire [1:0] in_buffer_i_layer;
	wire i_last;

	assign in_buffer_i_state = ctrl_o_state;
	assign in_buffer_i_layer = ctrl_o_layer;

	ctrl control_state(s_axi_aclk,s_axi_aresetn,s_axi_awaddr,s_axi_awprot,s_axi_awvalid,s_axi_awready,s_axi_wdata,s_axi_wstrb,s_axi_wvalid,s_axi_wready,s_axi_bresp,s_axi_bvalid,s_axi_bready,s_axi_araddr,s_axi_arprot,s_axi_arvalid,s_axi_arready,s_axi_rdata,s_axi_rresp,s_axi_rvalid,s_axi_rready,ctrl_o_state, ctrl_o_layer, ctrl_i_last);

	in_buffer idata_buffer(s_axis_aclk, s_axis_aresetn, s_axis_tready, s_axis_tdata, s_axis_tstrb, s_axis_tlast, s_axis_tvalid, in_buffer_i_state, in_buffer_i_layer, i_last, leds);

	conv conv(s_axi_aclk, s_axi_aresetn, w, w_valid, p, p_valid, o, o_valid);

	out_buffer odata_buffer(m_axis_aclk, m_axis_aresetn, m_axis_tvalid, m_axis_tdata, m_axis_tstrb, m_axis_tlast, m_axis_tready, o, o_valid, p_last);
endmodule
