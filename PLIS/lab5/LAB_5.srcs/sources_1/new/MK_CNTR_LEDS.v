`timescale 1ns / 1ps

module MK_CNTR_LEDS(
    // System
    input CLK,
    input RST,
    // STI 1.0
    input S_EX_REQ, // вход запроса
    input S_ADDR, // вход адреса
    input [2:0] S_CMD, // вход команды
    input [7:0] S_D_WR, // вход данных для записи
    output S_EX_ACK, // выход подтверждения
    output [7:0] S_D_RD, // выход данных чтения
    // LED
    output [7:0] LED, // управляющие сигналы светодиодов
    // RAM
    output reg [5:0] ADDR, // выход шины адреса ОЗУ
    input [7:0] DATA // вход шины данных ОЗУ
);

reg [7:0] MASK;
wire CE_MASK = S_EX_REQ & (~S_CMD[2]) & (~S_ADDR);

always @(posedge CLK, posedge RST) begin
    if (RST)
        MASK <= 8'b0;
    else if (CE_MASK)
        MASK <= S_D_WR;
end

assign LED = MASK & DATA;

wire CE_ADDR = S_EX_REQ & (~S_CMD[2]) & S_ADDR;

always @(posedge CLK, posedge RST) begin
    if (RST)
        ADDR <= 6'b0;
    else if (CE_ADDR)
        ADDR <= S_D_WR[5:0];
end

assign S_D_RD = (S_ADDR) ? {2'b0, ADDR} : MASK;

assign S_EX_ACK = 1'b1;

endmodule