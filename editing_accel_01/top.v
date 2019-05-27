
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
 wire [1:0]  ctrl_o_state;
 wire [1:0]  ctrl_o_current_layer;
 wire [5:0]  ctrl_o_current_ic;
 wire [5:0]  ctrl_o_current_oc;
 wire        ctrl_o_valid;
 wire [79:0] ctrl_o_bais_weights;
 wire        ctrl_o_bais_weights_valid;
 
 wire [1:0]  ib_i_state;
 wire [1:0]  ib_i_current_layer;
 wire [5:0]  ib_i_current_ic;
 wire [5:0]  ib_i_current_oc;
 wire        ib_i_valid;
 wire [23:0] ib_o_pe_1_row;
 wire [23:0] ib_o_pe_2_row;
 wire [23:0] ib_o_pe_3_row;
 wire [23:0] ib_o_pe_4_row;
 wire [23:0] ib_o_pe_5_row;
 wire        ib_o_pe_valid;
 wire        ib_o_img_row_done;
wire         ib_o_send_flg;

    wire  [5:0]  i_current_ic;
    wire  [79:0] i_params;
    wire         i_params_valid;
    wire [23:0] i_pe_1_row;
    wire [23:0] i_pe_2_row;
    wire [23:0] i_pe_3_row;
    wire [23:0] i_pe_4_row;
    wire [23:0] i_pe_5_row;
    wire        i_pe_valid;
    wire        img_row_done;
    wire            send_flg;
   assign ib_i_state = ctrl_o_state;
    assign ib_i_current_layer = ctrl_o_current_layer;
    assign ib_i_current_ic = ctrl_o_current_ic;
    assign ib_i_current_oc = ctrl_o_current_oc;
    assign ib_i_valid = ctrl_o_valid;
    assign i_current_ic = ctrl_o_current_ic;
    assign i_params = ctrl_o_bais_weights;
    assign i_params_valid = ctrl_o_bais_weights_valid;
 
    assign i_pe_1_row = ib_o_pe_1_row;
    assign i_pe_2_row = ib_o_pe_2_row;
    assign i_pe_3_row = ib_o_pe_3_row;
    assign i_pe_4_row = ib_o_pe_4_row;
    assign i_pe_5_row = ib_o_pe_5_row;
    assign i_pe_valid = ib_o_pe_valid;
    assign img_row_done = ib_o_img_row_done;
    assign send_flg = ib_o_send_flg;
    

	ctrl control_state(s_axi_aclk,s_axi_aresetn,s_axi_awaddr,s_axi_awprot,s_axi_awvalid,s_axi_awready,s_axi_wdata,s_axi_wstrb,s_axi_wvalid,s_axi_wready,s_axi_bresp,s_axi_bvalid,s_axi_bready,s_axi_araddr,s_axi_arprot,s_axi_arvalid,s_axi_arready,s_axi_rdata,s_axi_rresp,s_axi_rvalid,s_axi_rready, ctrl_o_state, ctrl_o_current_layer, ctrl_o_current_ic, ctrl_o_current_oc, ctrl_o_valid, ctrl_o_bais_weights, ctrl_o_bais_weights_valid);

	in_buffer idata_buffer(s_axis_aclk, s_axis_aresetn, s_axis_tready, s_axis_tdata, s_axis_tstrb, s_axis_tlast, s_axis_tvalid, ib_i_state, ib_i_current_layer, ib_i_current_ic, ib_i_current_oc, ib_i_valid, ib_o_pe_1_row, ib_o_pe_2_row, ib_o_pe_3_row, ib_o_pe_4_row, ib_o_pe_5_row, ib_o_pe_valid, ib_o_img_row_done, ib_o_send_flg);

	conv conv(m_axis_aclk,m_axis_aresetn,m_axis_tvalid,m_axis_tdata,m_axis_tstrb, m_axis_tlast,m_axis_tready,i_current_ic,i_params,i_params_valid,i_pe_1_row,i_pe_2_row,i_pe_3_row,i_pe_4_row, i_pe_5_row,i_pe_valid,img_row_done,send_flg);
	
endmodule
