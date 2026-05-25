module TOP(
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

DIVIDER # ( 
    .CNT_WDT(17),
    .DIV(100000)
) CLK_DIV (
    .CLK(CLK),
    .RST(~RST),
    .CEO(CE_1Khz)
);

// Buttons

BTN_FILTER # (
    .SIZE(3)
) BTN_FLTR_0 (
    .CLK(CLK),
    .RESET(~RST),
    .CLOCK_ENABLE(CE_1Khz),
    .IN_SIGNAL(BTN_0),
    .OUT_SIGNAL(GEN_PAR_ERR),
    .OUT_SIGNAL_ENABLE()
);

BTN_FILTER # (
    .SIZE(3)
) BTN_FLTR_1 (
    .CLK(CLK),
    .RESET(~RST),
    .CLOCK_ENABLE(CE_1Khz),
    .IN_SIGNAL(BTN_1),
    .OUT_SIGNAL(GEN_FRT_ERR),
    .OUT_SIGNAL_ENABLE()
);

UART DMI_UART( // UART controller
    .CLK(CLK),
    .RST(~RST),
    .RXD(UART_RXD),
    .TXD(UART_TXD),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_T(RX_DATA_T),
    .TX_RDY_T(TX_RDY_T),
    .TX_DATA_R(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R)
);

// Error generation
assign RX_DATA = {RX_DATA_T[9] | GEN_FRT_ERR,
                  RX_DATA_T[8] | GEN_PAR_ERR,
                  RX_DATA_T[7:0]};

wire [3:0] HEX_DATA;
wire [7:0] ASCII_DATA;
wire [3:0] DC_HEX_DATA;
wire [7:0] DC_ASCII_DATA;
wire [6:0] ADDR;
wire [7:0] DATA;
wire HEX_FLG;

DMI_FSM FSM(
    .clk(CLK),
    .rst(~RST),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_R(RX_DATA),
    .TX_RDY_T(TX_RDY_T),
    .TX_DATA_T(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R),
    .ASCII_DATA(ASCII_DATA),
    .HEX_FLG(HEX_FLG),
    .DC_HEX_DATA(DC_HEX_DATA),
    .HEX_DATA(HEX_DATA),
    .DC_ASCII_DATA(DC_ASCII_DATA),
    .ADDR(ADDR),
    .DATA(DATA)
);

DMI_ROM ROM(
    .ADDR(ADDR),
    .DATA(DATA)
);

DC_HEX_ASCII HEX_TO_ASCII (
    .HEX(HEX_DATA),
    .ASCII(DC_ASCII_DATA)
);
DC_ASCII_HEX ASCII_TO_HEX (
    .ASCII(ASCII_DATA),
    .HEX(DC_HEX_DATA),
    .HEX_FLG(HEX_FLG)
);

endmodule
