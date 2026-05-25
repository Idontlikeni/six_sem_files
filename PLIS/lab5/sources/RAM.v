`timescale 1ns / 1ps

module MK_RAM #(
    parameter AW = 6
)
(
    // System
    input CLK,
    // STI 1.0
    input S_EX_REQ, // запрос
    input [AW-1:0] S_ADDR, // адрес
    input [2:0] S_CMD, // команда
    input [7:0] S_D_WR, // данные для записи
    output S_EX_ACK, // подтверждение
    output [7:0] S_D_RD, // данные чтения
    // Memory Port
    input [AW-1:0] ADDR, // шина адреса ОЗУ
    output [7:0] DATA // шина данных ОЗУ
 );
    
reg [7:0] MEMORY [0:(2**AW)-1];

always @(posedge CLK)
    if (S_EX_REQ & ~S_CMD[2]) MEMORY[S_ADDR] <= S_D_WR;

assign S_D_RD = MEMORY[S_ADDR];
assign S_EX_ACK = 1'b1;

assign DATA = MEMORY[ADDR];

endmodule
