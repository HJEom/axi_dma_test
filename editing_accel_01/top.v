
`timescale 1 ns / 1 ps

    	module top
	(
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

    wire ctrl_o_load_state;
    wire [1:0] ctrl_o_current_layer;
    wire ctrl_i_last;

    wire ib_i_state;
    wire [1:0] ib_i_layer;
    wire [5:0] ib_o_cic;
    wire [25:0] ib_o_data;
    wire ib_o_data_valid;
    wire [23:0] ib_o_pe_1, ib_o_pe_2, ib_o_pe_3, ib_o_pe_4, ib_o_pe_5, ib_o_pe_6, ib_o_pe_7;
    wire ib_o_pe_valid;
    wire ib_o_conv_done;    // finish conv for 1 input ch
    wire ib_o_conv_done_1;  // out
    wire ib_o_conv_done_2;  // last
    
    wire [25:0] conv_i_param;
    wire conv_i_param_valid;
    wire [23:0] conv_i_pe_1, conv_i_pe_2, conv_i_pe_3, conv_i_pe_4, conv_i_pe_5, conv_i_pe_6, conv_i_pe_7;
    wire conv_i_pe_valid;
    wire [7:0] conv_o_pe_sum_1,  conv_o_pe_sum_2,  conv_o_pe_sum_3,  conv_o_pe_sum_4,  conv_o_pe_sum_5;
    wire conv_o_pe_sum_valid;
    
    wire [7:0] ob_i_pe_sum_1, ob_i_pe_sum_2, ob_i_pe_sum_3, ob_i_pe_sum_4, ob_i_pe_sum_5;
    wire ob_i_pe_sum_valid;
    wire [5:0] ob_i_cic;
    wire ob_i_conv_done, ob_i_conv_done_1, ob_i_conv_done_2;
    
    assign ctrl_i_last = ib_o_conv_done_2;
    assign ib_i_state = ctrl_o_load_state;
    assign ib_i_layer = ctrl_o_current_layer;
    assign conv_i_param = ib_o_data;
    assign conv_i_param_valid = ib_o_data_valid;
    assign conv_i_pe_1 = ib_o_pe_1;
    assign conv_i_pe_2 = ib_o_pe_2;
    assign conv_i_pe_3 = ib_o_pe_3;
    assign conv_i_pe_4 = ib_o_pe_4;
    assign conv_i_pe_5 = ib_o_pe_5;
    assign conv_i_pe_6 = ib_o_pe_6;
    assign conv_i_pe_7 = ib_o_pe_7;
    assign conv_i_pe_valid = ib_o_pe_valid;
    assign ob_i_pe_sum_1 = conv_o_pe_sum_1;
    assign ob_i_pe_sum_2 = conv_o_pe_sum_2;
    assign ob_i_pe_sum_3 = conv_o_pe_sum_3;
    assign ob_i_pe_sum_4 = conv_o_pe_sum_4;
    assign ob_i_pe_sum_5 = conv_o_pe_sum_5;
    assign ob_i_pe_sum_valid = conv_o_pe_sum_valid;
    assign ob_i_cic = ib_o_cic;
    assign ob_i_conv_done = ib_o_conv_done;
    assign ob_i_conv_done_1 = ib_o_conv_done_1;
    assign ob_i_conv_done_2 = ib_o_conv_done_2;
    
	ctrl control_state(s_axi_aclk,s_axi_aresetn,s_axi_awaddr,s_axi_awprot,s_axi_awvalid,s_axi_awready,s_axi_wdata,s_axi_wstrb,s_axi_wvalid,s_axi_wready,s_axi_bresp,s_axi_bvalid,s_axi_bready,s_axi_araddr,s_axi_arprot,s_axi_arvalid,s_axi_arready,s_axi_rdata,s_axi_rresp,s_axi_rvalid,s_axi_rready,ctrl_o_load_state, ctrl_o_current_layer, ctrl_i_last);

	in_buffer idata_buffer(s_axis_aclk, s_axis_aresetn, s_axis_tready, s_axis_tdata, s_axis_tstrb, s_axis_tlast, s_axis_tvalid, ib_i_state, ib_i_layer, ib_o_cic,ib_o_data, ib_o_data_valid, ib_o_pe_1, ib_o_pe_2, ib_o_pe_3, ib_o_pe_4, ib_o_pe_5, ib_o_pe_6, ib_o_pe_7, ib_o_pe_valid, ib_o_conv_done, ib_o_conv_done_1, ib_o_conv_done_2);

	conv conv(s_axi_aclk, s_axi_aresetn, conv_i_param, conv_i_param_valid, conv_i_pe_1, conv_i_pe_2, conv_i_pe_3, conv_i_pe_4, conv_i_pe_5, conv_i_pe_6, conv_i_pe_7, conv_i_pe_valid, conv_o_pe_sum_1,  conv_o_pe_sum_2,  conv_o_pe_sum_3,  conv_o_pe_sum_4,  conv_o_pe_sum_5, conv_o_pe_sum_valid);

	out_buffer odata_buffer(m_axis_aclk, m_axis_aresetn, m_axis_tvalid, m_axis_tdata, m_axis_tstrb, m_axis_tlast, m_axis_tready, ob_i_pe_sum_1, ob_i_pe_sum_2, ob_i_pe_sum_3, ob_i_pe_sum_4, ob_i_pe_sum_5, ob_i_pe_sum_valid, ob_i_cic, ob_i_conv_done, ob_i_conv_done_1, ob_i_conv_done_2);
    
endmodule
