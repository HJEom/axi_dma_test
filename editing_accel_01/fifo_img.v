`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/26 11:40:47
// Design Name: 
// Module Name: fifo_img
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


module fifo_img#(
    parameter integer DATA_WIDTH = 24,
    parameter integer DATA_DEPTH = 24
    )
    (
    input clk,
    input rstn,
    input ce,
    input [17:0] addr,
    input [DATA_WIDTH*3-1:0] d,
    input we, // 1 : write, 0 : read
    output [DATA_WIDTH*7-1:0] q
    );
    
    (* ram_style = {"block"} *) reg [DATA_WIDTH-1:0] fifo[0:DATA_DEPTH-1];
    
    always@(posedge clk) begin
        if(we && ce) begin
            fifo[addr] <= d[23:16];
            fifo[addr+1] <= d[15:8];
            fifo[addr+2] <= d[7:0];
        end
    end
    
    assign q = (!(we) && ce) ? {fifo[addr],fifo[addr+1],fifo[addr+2],fifo[addr+3],fifo[addr+4],fifo[addr+5],fifo[addr+6]} : {(DATA_WIDTH*7){1'b0}};
    
endmodule
