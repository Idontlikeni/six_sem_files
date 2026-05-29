`timescale 1ns / 1ps

module LAB5_TOP(
    // System
    input CLK,
    input SYS_NRST,
    // UART
    input UART_RXD,
    output UART_TXD,
    // LEDs
    output [7:0] LED
);

wire RST;
reg [1:0] RST_S;
wire CE_1kHz;
wire RX_DATA_EN;
wire [9:0] RX_DATA_T;
wire [7:0] RX_DATA;
wire HEX_FLG;
wire [3:0] DC_ASCII_HEX;
wire CMD_RDY_T;
wire [50:0] CMD_DATA_T;
wire CMD_RDY_R;
wire RES_RDY_T;
wire [36:0] RES_DATA_T;
wire RES_RDY_R;
wire T_S_EX_REQ;
wire [23:0] T_S_ADDR;
wire [2:0] T_S_CMD;
wire [7:0] T_S_D_WR;
wire T_S_EX_ACK;
wire [7:0] T_S_D_RD;
wire I0_S_EX_REQ;
wire I0_S_ADDR;
wire [2:0] I0_S_CMD;
wire [7:0] I0_S_D_WR;
wire I0_S_EX_ACK;
wire [7:0] I0_S_D_RD;
wire I1_S_EX_REQ;
wire [5:0] I1_S_ADDR;
wire [2:0] I1_S_CMD;
wire [7:0] I1_S_D_WR;
wire I1_S_EX_ACK;
wire [7:0] I1_S_D_RD;
wire [5:0] CNTR_RAM_ADDR;
wire [7:0] CNTR_RAM_DATA;
wire [6:0] ROM_ADDR;
wire [7:0] ROM_DATA;
wire [3:0] HEX_DATA;
wire [7:0] DC_ASCII_DATA;
wire TX_RDY_T;
wire [7:0] TX_DATA_T;
wire TX_RDY_R;

// Reset sync
always @(posedge CLK, negedge SYS_NRST) begin
    if (!SYS_NRST) 
        RST_S <= 2'b11;
    else 
        RST_S <= {RST_S[0], 1'b0};
end
assign RST = RST_S[1];


M_CLOCK_DIVIDER #(.MOD(100000)) DIV_1kHz (
    .clk_in(CLK),
    .reset(RST),
    .clk_out(CE_1kHz)
);

UART UART (
    .CLK(CLK),
    .RST(RST),
    .RXD(UART_RXD),
    .TXD(UART_TXD),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_T(RX_DATA_T),
    .TX_RDY_T(TX_RDY_T),
    .TX_DATA_R(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R)
);

assign RX_DATA = RX_DATA_T[7:0];

ANALYZER ANALYZER (
    .CLK(CLK),
    .RST(RST),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_R(RX_DATA),
    .ASCII_DATA(),
    .HEX_FLG(HEX_FLG),
    .DC_ASCII_HEX(DC_ASCII_HEX),
    .CMD_RDY_T(CMD_RDY_T),
    .CMD_DATA_T(CMD_DATA_T),
    .CMD_RDY_R(CMD_RDY_R)
);

DC_ASCII_HEX ASCII_TO_HEX (
    .ASCII(RX_DATA),
    .HEX(DC_ASCII_HEX),
    .HEX_FLG(HEX_FLG)
);

DC_HEX_ASCII HEX_TO_ASCII (
    .HEX(HEX_DATA),
    .ASCII(DC_ASCII_DATA)
);

ROM ROM (
    .ADDR(ROM_ADDR),
    .DATA(ROM_DATA)
);

GEN_MSG GEN_MSG (
    .CLK(CLK),
    .RST(RST),
    .TX_RDY_T(TX_RDY_T),
    .TX_DATA_T(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R),
    .RES_RDY_T(RES_RDY_T),
    .RES_DATA_R(RES_DATA_T),
    .RES_RDY_R(RES_RDY_R),
    .HEX_DATA(HEX_DATA),
    .DC_ASCII_DATA(DC_ASCII_DATA),
    .ADDR(ROM_ADDR),
    .DATA(ROM_DATA)
);

HANDLER_CMD HANDLER (
    .CLK(CLK),
    .RST(RST),
    .CMD_RDY_T(CMD_RDY_T),
    .CMD_DATA_R(CMD_DATA_T),
    .CMD_RDY_R(CMD_RDY_R),
    .S_EX_REQ(T_S_EX_REQ),
    .S_ADDR(T_S_ADDR),
    .S_CMD(T_S_CMD),
    .S_D_WR(T_S_D_WR),
    .S_EX_ACK(T_S_EX_ACK),
    .S_D_RD(T_S_D_RD),
    .RES_RDY_T(RES_RDY_T),
    .RES_DATA_T(RES_DATA_T),
    .RES_RDY_R(RES_RDY_R)
);

CNTR_LEDS CNTR_LEDS (
    .CLK(CLK),
    .RST(RST),
    .S_EX_REQ(I0_S_EX_REQ),
    .S_ADDR(I0_S_ADDR),
    .S_CMD(I0_S_CMD),
    .S_D_WR(I0_S_D_WR),
    .S_EX_ACK(I0_S_EX_ACK),
    .S_D_RD(I0_S_D_RD),
    .LED(LED),
    .ADDR(CNTR_RAM_ADDR),
    .DATA(CNTR_RAM_DATA)
);

RAM #(.AW(6)) RAM (
    .CLK(CLK),
    .S_EX_REQ(I1_S_EX_REQ),
    .S_ADDR(I1_S_ADDR),
    .S_CMD(I1_S_CMD),
    .S_D_WR(I1_S_D_WR),
    .S_EX_ACK(I1_S_EX_ACK),
    .S_D_RD(I1_S_D_RD),
    .ADDR(CNTR_RAM_ADDR),
    .DATA(CNTR_RAM_DATA)
);

INFS_8B SYSTEM_BUS (
    .T_S_EX_REQ(T_S_EX_REQ),
    .T_S_ADDR(T_S_ADDR),
    .T_S_CMD(T_S_CMD),
    .T_S_D_WR(T_S_D_WR),
    .T_S_EX_ACK(T_S_EX_ACK),
    .T_S_D_RD(T_S_D_RD),
    .I0_S_EX_REQ(I0_S_EX_REQ),
    .I0_S_ADDR(I0_S_ADDR),
    .I0_S_CMD(I0_S_CMD),
    .I0_S_D_WR(I0_S_D_WR),
    .I0_S_EX_ACK(I0_S_EX_ACK),
    .I0_S_D_RD(I0_S_D_RD),
    .I1_S_EX_REQ(I1_S_EX_REQ),
    .I1_S_ADDR(I1_S_ADDR),
    .I1_S_CMD(I1_S_CMD),
    .I1_S_D_WR(I1_S_D_WR),
    .I1_S_EX_ACK(I1_S_EX_ACK),
    .I1_S_D_RD(I1_S_D_RD)
);

endmodule
