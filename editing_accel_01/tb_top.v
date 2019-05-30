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
		integer fd_w, fo, fo_int;
		integer i_data1, i_data2, i_data3, i_data4;
		
top top        (clk, rstn,s_axi_awaddr,s_axi_awprot, s_axi_awvalid,s_axi_awready, s_axi_wdata, s_axi_wstrb,s_axi_wvalid, s_axi_wready, s_axi_bresp,  s_axi_bvalid,s_axi_bready, s_axi_araddr, s_axi_arprot, s_axi_arvalid,s_axi_arready,s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready, clk,rstn,m_axis_tvalid,m_axis_tdata,m_axis_tstrb,m_axis_tlast,m_axis_tready,clk,rstn, s_axis_tready, s_axis_tdata,s_axis_tstrb,s_axis_tlast,s_axis_tvalid);
		always #5 clk = ~clk;
		
    initial begin
    
        fo = $fopen("/home/eom/files/my_git/my_accel/axi_dma_test/test_file/odata.txt","w");
        fo_int = $fopen("/home/eom/files/my_git/my_accel/axi_dma_test/test_file/odata_int.txt","w");
        fd_w = $fopen("/home/eom/files/my_git/my_accel/axi_dma_test/test_file/i_low_img.txt","r");
    
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
        
        @(posedge clk) 
        #2 rstn = 1;
        for (j=0; j<1; j=j+1) begin
        /////////////////////// wdata 1
        repeat(4) @(posedge clk);
         s_axi_awaddr = 0;
        s_axi_awvalid = 1;
        @(posedge clk);
         
        s_axi_wvalid =1;
        s_axi_wdata = 3;
        repeat(2)@(posedge clk);
         s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        /////////////////////// wdata 2
        repeat(4) @(posedge clk);
         s_axi_awaddr = 4;
        s_axi_awvalid = 1;
        @(posedge clk);
         
        s_axi_wvalid =1;
        s_axi_wdata = 32'h00040602;
        repeat(2)@(posedge clk);
         s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        
                /////////////////////// wdata 3
        repeat(4) @(posedge clk);
         s_axi_awaddr = 8;
        s_axi_awvalid = 1;
        @(posedge clk);
         
        s_axi_wvalid =1;
        s_axi_wdata = 32'h000202fe;
        repeat(2)@(posedge clk);
         s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        
                /////////////////////// wdata 4
        repeat(4) @(posedge clk);
         s_axi_awaddr = 12;
        s_axi_awvalid = 1;
        @(posedge clk);
         
        s_axi_wvalid =1;
        s_axi_wdata = 32'h0006fffe;
        repeat(2)@(posedge clk);
         s_axi_wvalid = 0;
        s_axi_awvalid = 0;
        
        repeat(4)@(posedge clk);
        for (i=0; i<576; i=i+1)begin
        @(posedge clk);
        i_data1 = $fscanf(fd_w, "%d\n",s_axis_tdata[31:24]);
        i_data2 = $fscanf(fd_w, "%d\n",s_axis_tdata[23:16]);
        i_data3 = $fscanf(fd_w, "%d\n",s_axis_tdata[15:8]);
        i_data4 = $fscanf(fd_w, "%d\n",s_axis_tdata[7:0]);
        s_axis_tvalid = 1;
        if(i==575) s_axis_tlast = 1;
        end
        @(posedge clk);
        s_axis_tvalid = 0;
         s_axis_tlast = 0;
         repeat(4)@(posedge clk);
         for (i=0; i<576; i=i+1)begin
         @(posedge clk);
          m_axis_tready = 1;
         end
         @(posedge clk);
        
        repeat(2000) @(posedge clk);
        end
        $fclose(fd_w);
        $fclose(fo);
        $finish;
        
    end

always@(posedge clk) begin
    if(m_axis_tvalid) begin
        $fwrite(fo,"%02x\n", m_axis_tdata[31:24]);
        $fwrite(fo,"%02x\n", m_axis_tdata[23:16]);
        $fwrite(fo,"%02x\n", m_axis_tdata[15:8]);
        $fwrite(fo,"%02x\n", m_axis_tdata[7:0]);
        $fwrite(fo_int,"%d\n", m_axis_tdata[31:24]);
                $fwrite(fo_int,"%d\n", m_axis_tdata[23:16]);
                $fwrite(fo_int,"%d\n", m_axis_tdata[15:8]);
                $fwrite(fo_int,"%d\n", m_axis_tdata[7:0]);
        
        end
end


endmodule
