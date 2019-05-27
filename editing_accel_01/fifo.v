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
    parameter integer DATA_WIDTH = 24,
    parameter integer DATA_DEPTH = 24
    )
    (
    input clk,
    input rstn,
    input ce,
    input [17:0] addr,
    input [DATA_WIDTH-1:0] d,
    input we, // 1 : write, 0 : read
    output [DATA_WIDTH-1:0] q
    );
    
    (* ram_style = {"block"} *) reg [DATA_WIDTH-1:0] fifo[0:DATA_DEPTH-1];
    
    always@(posedge clk) begin
        if(we && ce) fifo[addr] <= d;
    end
    
    assign q = (!(we) && ce) ? fifo[addr] : {(DATA_WIDTH){1'b0}};
    
endmodule
