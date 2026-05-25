`timescale 1ns / 1ps

module MK_TOP(
    //  system
    input CLK, // 100 ћ√ц
    input SYS_NRST,
    // buttons
    input BTN_0,
    input BTN_1,
    // UART
    input UART_RXD,
    output UART_TXD
);
wire RST;
reg [1:0] RST_S;
wire CE_1kHz;
wire GEN_FRT_ERR;
wire GEN_PAR_ERR;
wire RX_DATA_EN;
wire [9:0] RX_DATA_T;
wire [9:0] RX_DATA;
wire TX_RDY_T;
wire [7:0] TX_DATA_T;
wire TX_RDY_R;
wire HEX_FLG;
wire [3:0] ASCII_HEX_DATA;
wire [3:0] FSM_HEX_DATA;
wire [7:0] DC_ASCII_DATA;
wire [6:0] ROM_ADDR;
wire [7:0] ROM_DATA;

// Reset Synchronizer
// SYS_NRST - активный низкий (кнопка)
// RST - активный высокий
always @(posedge CLK, negedge SYS_NRST)
    if (!SYS_NRST) RST_S <= 2'b11;
    else RST_S <= {RST_S[0], 1'b0};

assign RST = RST_S[1];


// Clock Divider
M_CLOCK_DIVIDER #(
    .MOD(100000)
) DIV_1kHz (
    .clk_in(CLK),
    .reset(RST),
    .clk_out(CE_1kHz)
);

// Filter  for B0
M_BTN_FILTER #(
    .SIZE(3)
) BTN_0_FLTR (
    .CLK(CLK),
    .RESET(RST),
    .IN_SIGNAL(BTN_0),
    .CLOCK_ENABLE(CE_1kHz),
    .OUT_SIGNAL(GEN_FRT_ERR),
    .OUT_SIGNAL_ENABLE()
);

// Filter for BTN_1
M_BTN_FILTER #(
    .SIZE(3)
) BTN_1_FLTR (
    .CLK(CLK),
    .RESET(RST),
    .IN_SIGNAL(BTN_1),
    .CLOCK_ENABLE(CE_1kHz),
    .OUT_SIGNAL(GEN_PAR_ERR),
    .OUT_SIGNAL_ENABLE()
);

// Controller UART
MK_UART UART (
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

assign RX_DATA = {RX_DATA_T[9] | GEN_FRT_ERR, RX_DATA_T[8] | GEN_PAR_ERR, RX_DATA_T[7:0]};

// FSM
MK_FSM FSM(
    .CLK(CLK),
    .RST(RST),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_R(RX_DATA),
    .TX_RDY_T(TX_RDY_T),
    .TX_DATA_T(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R),
    .ASCII_DATA(),
    .HEX_FLG(HEX_FLG),
    .DC_HEX_DATA(ASCII_HEX_DATA),
    .HEX_DATA(FSM_HEX_DATA),
    .DC_ASCII_DATA(DC_ASCII_DATA),
    .ADDR(ROM_ADDR),
    .DATA(ROM_DATA)
);

// ASCII_to_HEX
MK_DC_ASCII_HEX ASCII_to_HEX(
    .ASCII(RX_DATA[7:0]),
    .HEX(ASCII_HEX_DATA),
    .HEX_FLG(HEX_FLG)
);

// HEX_to_ASCII
MK_DC_HEX_ASCII HEX_to_ASCII(
    .HEX(FSM_HEX_DATA),
    .ASCII(DC_ASCII_DATA)
);

MK_ROM ROM (
.ADDR(ROM_ADDR),
.DATA(ROM_DATA)
);

endmodule
