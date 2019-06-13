`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/30 16:05:07
// Design Name: 
// Module Name: manage_overflow
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


module manage_overflow(
input signed [15:0] o_pe_row_1,
input signed [15:0] o_pe_row_2,
input signed [15:0] o_pe_row_3,
input o_pe_valid,
output reg signed [7:0] o_pe_col_sum_1
    );
    
    wire signed [10:0] tmp1;
        
    assign tmp1 = o_pe_row_1 + o_pe_row_2+ o_pe_row_3;

    always@(*) begin
        if((o_pe_valid) && !(tmp1[10]) && (tmp1[9:8] > 0)) o_pe_col_sum_1 = 8'b01111111;
        else if((o_pe_valid) && (tmp1[10]) && (tmp1[9:8] != 2'b11)) o_pe_col_sum_1 = 8'b10000000;
        else o_pe_col_sum_1 = {tmp1[10], tmp1[6:0]};
    end
    
endmodule
