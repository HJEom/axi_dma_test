`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/18 14:55:10
// Design Name: 
// Module Name: tb_myip_v1_0
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


module tb_myip_v1_0;

reg clk, resetn;
reg [31:0] idata;
reg ilast;
reg ivalid;
wire iready;

reg oready;
wire [31:0] odata;
wire olast;
wire ovalid;
wire ostrb;

myip_v1_0 top(
.s00_axis_aclk(clk),
.s00_axis_aresetn(resetn),
.s00_axis_tready(iready),
.s00_axis_tdata(idata),
.s00_axis_tstrb(),
.s00_axis_tlast(ilast),
.s00_axis_tvalid(ivalid),
.m00_axis_aclk(clk),
.m00_axis_aresetn(resetn),
.m00_axis_tvalid(ovalid),
.m00_axis_tdata(odata),
.m00_axis_tstrb(ostrb),
.m00_axis_tlast(olast),
.m00_axis_tready(oready)
);

initial begin
    clk = 0;
    resetn = 0;
    idata = 0;
    ilast = 0;
    ivalid = 0;
    oready = 0;
    
    @(posedge clk);
    #1  resetn = 1;
    @(posedge clk);
    #1  oready = 1;
        ivalid = 1;
    @(posedge clk);
    #1  idata = 32'd1;
    @(posedge clk);
    #1  idata = 32'd2;
    @(posedge clk);
    #1  idata = 32'd3;
    @(posedge clk);
    #1  idata = 32'd4;
    @(posedge clk);
    #1  idata = 32'd5;
    @(posedge clk);
    #1  idata = 32'd6;
    @(posedge clk);
    #1  idata = 32'd7;
    @(posedge clk);
    #1  idata = 32'd8;
    @(posedge clk);
    #1  idata = 32'd9;
    @(posedge clk);
    #1  idata = 32'd10;
        @(posedge clk);
    #1  idata = 32'd10;
        @(posedge clk);
    #1  idata = 32'd10;
        @(posedge clk);
    #1  idata = 32'd10;
        @(posedge clk);
    #1  idata = 32'd10;
        @(posedge clk);
    #1  idata = 32'd10;
        ilast = 1;
    @(posedge clk);
    #1  ilast = 0;
        ivalid = 0;
        
    repeat(50) @(posedge clk);
    $finish;
end

always #5 clk = ~clk;



endmodule
