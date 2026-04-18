`timescale 1ns / 1ps

module TOP_LA(
    input CLK,
    input SYS_NRST,
    input BTN_0,
    input BTN_1,
    input UART_RXD,
    output UART_TXD
);
wire RST;
reg [1:0] RST_S; // Reset sync

wire CE_1Khz;
wire GEN_FRT_ERR;
wire GEN_PAR_ERR;
wire RX_DATA_EN;
wire [9:0] RX_DATA_T;
wire [9:0] RX_DATA;

wire TX_RDY_T;
wire [7:0] TX_DATA_T;
wire TX_DRDY_R;

always @ (posedge CLK, posedge SYS_NRST) // reset syncronizer
    if(SYS_NRST) RST_S <= 2'b11;
    else RST_S <= {RST_S[0], 1'b0};
assign RST = RST_S[1];

LA_DIVIDER # ( 
    .CNT_WDT(17),
    .DIV(100000)
) CLK_DIV (
    .CLK(CLK),
    .RST(RST),
    .CEO(CE_1Khz)
);

// Buttons
LA_BTN_FLTR # (
    .CNTR_WIDTH(3)
) LA_BTN_FLTR_0 (
    .CLK(CLK),
    .RST(RST),
    .CE(CE_1Khz),
    .BTN_IN(BTN_0),
    .BTN_OUT(GEN_FRT_ERR),
    .BTN_CEO()
);

LA_BTN_FLTR # (
    .CNTR_WIDTH(3)
) LA_BTN_FLTR_1 (
    .CLK(CLK),
    .RST(RST),
    .CE(CE_1Khz),
    .BTN_IN(BTN_1),
    .BTN_OUT(GEN_PAR_ERR),
    .BTN_CEO()
);

UART DMI_UART( // UART controller
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

// Error generation
assign RX_DATA = {RX_DATA[9] | GEN_FRT_ERR,
                  RX_DATA[8] | GEN_PAR_ERR,
                  RX_DATA_T[7:0]};

wire [3:0] HEX_DATA;
wire [7:0] ASCII_DATA;
wire [3:0] DC_HEX_DATA;
wire [7:0] DC_ASCII_DATA;
wire [6:0] ADDR;
wire [7:0] DATA;
wire HEX_FLG;

DMI_FSM FSM(
    .CLK(CLK),
    .RST(RST),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_R(RX_DATA),
    .TX_RDYT(TX_RDY_T),
    .TX_DATA_T(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R),
    .ASCII_DATA(ASCII_DATA),
    .HEX_FLG(HEX_FLG),
    .DC_HEX_DATA(DC_HEX_DATA),
    .HEX_DATA(HEX_DATA),
    .DC_ASCII_DATA(),
    .ADDR(ADDR),
    .DATA(DATA)
);

DMI_rom ROM(
    .ADDR(ADDR),
    .DATA(DATA)
);

LA_DC_HEX_ASCII HEX_TO_ASCII (
    .HEX(HEX_DATA),
    .ASCII(DC_ASCII_DATA)
);
LA_DC_ASCII_HEX ASCII_TO_HEX (
    .ASCII(ASCII_DATA),
    .HEX(DC_HEX_DATA),
    .HEX_FLG()
);

endmodule
