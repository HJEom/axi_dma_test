`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/26 11:00:43
// Design Name: 
// Module Name: fifo
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


module fifo#(
    parameter integer DATA_WIDTH = 8,
    parameter integer DATA_DEPTH = 2304 
    )
    (
    input clk,
    input rstn,
    input ce,
    input we, // 1 : write, 0 : read
    input [11:0] addr,
    input [DATA_WIDTH*4-1:0] d,
    output  [DATA_WIDTH*5-1:0] q
    );
    
    (* ram_style = {"block"} *) reg [DATA_WIDTH-1:0] fifo[0:DATA_DEPTH-1];
    
    always@(posedge clk) begin
        if(we && ce) begin
		fifo[addr] <= d[31:24];
         fifo[addr+1] <= d[23:16];
         fifo[addr+2] <= d[15:8];
         fifo[addr+3] <= d[7:0];

	end
	end
assign q = (!(we) && ce) ? {fifo[addr], fifo[addr+48], fifo[addr+96], fifo[addr+144], fifo[addr+192]} : {(DATA_WIDTH*5){1'b0}};
    
endmodule
