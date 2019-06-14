`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/26 18:39:20
// Design Name: 
// Module Name: tb_top
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


module tb_top;

		reg [32-1 : 0] s_axi_awaddr;
		reg [2 : 0] s_axi_awprot;
		reg  s_axi_awvalid;
		wire  s_axi_awready;
		reg [32-1 : 0] s_axi_wdata;
		reg [(32/8)-1 : 0] s_axi_wstrb;
		reg  s_axi_wvalid;
		wire  s_axi_wready;
		wire [1 : 0] s_axi_bresp;
		wire  s_axi_bvalid;
		reg  s_axi_bready;
		reg [4-1 : 0] s_axi_araddr;
		reg [2 : 0] s_axi_arprot;
		reg  s_axi_arvalid;
		wire  s_axi_arready;
		wire [32-1 : 0] s_axi_rdata;
		wire [1 : 0] s_axi_rresp;
		wire  s_axi_rvalid;
		reg  s_axi_rready;

		// Ports of Axi Master Bus Interface M_AXIS
		wire  m_axis_tvalid;
		wire [32-1 : 0] m_axis_tdata;
		wire [(32/8)-1 : 0] m_axis_tstrb;
		wire  m_axis_tlast;
		reg  m_axis_tready;
		
		wire  s_axis_tready;
		reg [32-1 : 0] s_axis_tdata;
		reg [(32/8)-1 : 0] s_axis_tstrb;
		reg  s_axis_tlast;
		reg  s_axis_tvalid;
		
		reg clk;
		reg rstn;
		integer j, i;
		integer fd_param_w, fd_param_b;
		integer fd_i_image;
		
		integer scan_w1, scan_w2, scan_w3, scan_b, scan_i_image1, scan_i_image2, scan_i_image3, scan_i_image4;
		
top top        (clk, rstn,s_axi_awaddr,s_axi_awprot, s_axi_awvalid,s_axi_awready, s_axi_wdata, s_axi_wstrb,s_axi_wvalid, s_axi_wready, s_axi_bresp,  s_axi_bvalid,s_axi_bready, s_axi_araddr, s_axi_arprot, s_axi_arvalid,s_axi_arready,s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready, clk,rstn,m_axis_tvalid,m_axis_tdata,m_axis_tstrb,m_axis_tlast,m_axis_tready,clk,rstn, s_axis_tready, s_axis_tdata,s_axis_tstrb,s_axis_tlast,s_axis_tvalid);
		always #5 clk = ~clk;
		
    initial begin
    
        fd_param_w = $fopen("/home/eom/files/my_git/my_accel/axi_dma_test/test_file/param_w.txt","r");
        fd_param_b = $fopen("/home/eom/files/my_git/my_accel/axi_dma_test/test_file/param_b.txt","r");
        fd_i_image = $fopen("/home/eom/files/my_git/my_accel/axi_dma_test/test_file/i_low_img.txt","r");
    
        clk = 0;
        rstn = 0;
        s_axi_awaddr=0; 
        s_axi_awvalid=0;
        s_axi_wdata=0;
        s_axi_wvalid=0;
        s_axi_bready=1;
        
        s_axis_tdata=0;
        s_axis_tlast=0;
        s_axis_tvalid=0;
        
        m_axis_tready=0;
        
        @(posedge clk);
        #2 rstn = 1;
        repeat(2) @(posedge clk);
        
        
        // send control signal to ctrl module
        s_axi_awaddr = 0;
        s_axi_awvalid = 1;
        @(posedge clk)
        
        s_axi_wdata=1;
        s_axi_wvalid=1;
        repeat(3) @(posedge clk)
        if(s_axi_bvalid == 1) begin
           s_axi_wvalid = 0;
           s_axi_awvalid = 0; 
        end;
        
        s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        @(posedge clk);
        
        // load parameter
        s_axis_tvalid = 1;
        for(i=0; i<12672; i=i+1) begin
            scan_w1 = $fscanf(fd_param_w, "%d\n", s_axis_tdata[23:16]);
            scan_w2 = $fscanf(fd_param_w, "%d\n", s_axis_tdata[15:8]);
            scan_w3 = $fscanf(fd_param_w, "%d\n", s_axis_tdata[7:0]);
            if(i<129) scan_b = $fscanf(fd_param_b, "%d\n", s_axis_tdata[31:24]);
            if(i==12671) s_axis_tlast = 1;
            @(posedge clk);
        end
        
        s_axis_tlast = 0;
        s_axis_tvalid = 0;
        @(posedge clk);
        
        // send control signal to ctrl module
        s_axi_awaddr = 0;
        s_axi_awvalid = 1;
        @(posedge clk);
        
        s_axi_wdata=2;
        s_axi_wvalid=1;
        repeat(3) @(posedge clk)
        if(s_axi_bvalid == 1) begin
           s_axi_wvalid = 0;
           s_axi_awvalid = 0; 
        end;
        
        s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        @(posedge clk);
        
        // load input image
        s_axis_tvalid = 1;
        for(j=0; j<12; j=j+1) begin
        for(i=0; i<48; i=i+1) begin
            if(j == 0) s_axis_tdata = 32'h03020100;
            else if(j == 1) s_axis_tdata = 32'h07060504;
            else if(j == 2) s_axis_tdata = 32'h0b0a0908;
            else if(j == 3) s_axis_tdata = 32'h0f0e0d0c;
            else if(j == 4) s_axis_tdata = 32'h13121110;
            else if(j == 5) s_axis_tdata = 32'h17161514;
            else if(j == 6) s_axis_tdata = 32'h1b1a1918;
            else if(j == 7) s_axis_tdata = 32'h1f1e1d1c;
            else if(j == 8) s_axis_tdata = 32'h23222120;
            else if(j == 9) s_axis_tdata = 32'h27262524;
            else if(j == 10) s_axis_tdata = 32'h2b2a2928;
            else if(j == 11) s_axis_tdata = 32'h2f2e2d2c;
            if(i == 47 & j == 11) s_axis_tlast = 1;
            @(posedge clk);
        end
        end
//        for(j=0; j<12; j=j+1) begin
//        for(i=0; i<48; i=i+1) begin
//            scan_i_image1 = $fscanf(fd_i_image, "%d\n", s_axis_tdata[7:0]);
//            scan_i_image2 = $fscanf(fd_i_image, "%d\n", s_axis_tdata[15:8]);
//            scan_i_image3 = $fscanf(fd_i_image, "%d\n", s_axis_tdata[23:16]);
//            scan_i_image4 = $fscanf(fd_i_image, "%d\n", s_axis_tdata[31:24]);
//            if(i == 47 & j == 11) s_axis_tlast = 1;
//            @(posedge clk);
//        end
//        end
        
        s_axis_tlast = 0;
        s_axis_tvalid = 0;
        @(posedge clk);
        
        // send control signal to ctrl module
        s_axi_awaddr = 0;
        s_axi_awvalid = 1;
        @(posedge clk);
        
        s_axi_wdata=3;
        s_axi_wvalid=1;
        repeat(3) @(posedge clk)
        if(s_axi_bvalid == 1) begin
           s_axi_wvalid = 0;
           s_axi_awvalid = 0; 
        end;
        
        s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        @(posedge clk);
        
        
        repeat(5000) @(posedge clk);
        
        
        $finish;
        
    end

endmodule
