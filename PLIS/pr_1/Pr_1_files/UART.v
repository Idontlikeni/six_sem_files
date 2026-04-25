module UART(
    input CLK,
    input RST,

    output reg  TXD,
    input RXD,

    output reg       RX_DATA_EN,
    output reg [9:0] RX_DATA_T, // [9:8] ERR, [7:0] DATA
                                // 00 - No err
                                // 01 - parity err
                                // 10 - format window err
                                // 11 - both
    input            TX_RDY_T,
    input      [7:0] TX_DATA_R,
    output reg       TX_RDY_R
);
reg [2:0] RXD_SYNC;
wire UART_CE;
// Synchro
wire RXD_RG;
always@(posedge CLK,posedge RST)
    begin
        if(RST) RXD_SYNC <= 3'b111;
        else RXD_SYNC <= {RXD_SYNC[0], RXD};
    end
assign RXD_RG = RXD_SYNC[1];

//RX_SAMP_COUNT
reg [3:0] RX_SAMP_CT;
reg RXCT_R;
wire RX_CE;

always@(posedge CLK, posedge RST)
    begin
        if(RST) RX_SAMP_CT <= 4'b0000;
        else if(RXCT_R) RX_SAMP_CT <= 4'b0000;
        else if(UART_CE) RX_SAMP_CT <= RX_SAMP_CT + 1'b1;
    end
assign RX_CE = UART_CE & ~RX_SAMP_CT[3] & RX_SAMP_CT[2] & RX_SAMP_CT[1] & RX_SAMP_CT[0]; // if CE and RX_SAMP_CT == 4'b0111 (4'd15)

//TX_SAMP_COUNT
reg [3:0] TX_SAMP_CT;
reg TXCT_R;
wire TX_CE;

always@(posedge CLK,posedge RST)
    begin
        if(RST) TX_SAMP_CT <= 3'b0000;
        else if(TXCT_R) TX_SAMP_CT <= 3'b0000;
        else if(UART_CE) TX_SAMP_CT <= TX_SAMP_CT + 1'b1;
    end
assign TX_CE = UART_CE & (TX_SAMP_CT == 4'b1111);

//RX_FSM
localparam [2:0] RX_IDLE =  3'd0;
localparam [2:0] RX_RSTRB = 3'd1;
localparam [2:0] RX_RDT =   3'd2;
localparam [2:0] RX_RPARB = 3'd3;
localparam [2:0] RX_RSTB1 = 3'd4;
localparam [2:0] RX_RSTB2 = 3'd5;
localparam [2:0] RX_WEND =  3'd6;

reg [2:0] RX_FSM;
reg [2:0] RX_DATA_CT;
// reg RXT_RG;
always@(posedge CLK, posedge RST)
begin
    if(RST)
        begin
            RX_FSM <= RX_IDLE;
            RX_DATA_EN <= 0;
            RX_DATA_T <= 0;
            RX_DATA_CT <= 0;
            RXCT_R <= 1'b1;
        end
    else
        case(RX_FSM)
            RX_IDLE:begin // Waiting for start bit
                RX_DATA_EN <= 1'b0;
                if(~RXD_RG)
                begin
                    RX_FSM <= RX_RSTRB;
                    RX_DATA_T[9] <= 1'b0; // RX_DATA_T[9]?
                    RXCT_R <= 1'b0;
                end
            end
            RX_RSTRB:begin // recieve start bit
                if(RX_CE) begin
                    if(RXD_RG) begin
                        RX_FSM <= RX_IDLE;
                        RXCT_R <= 1'd1;
                    end else RX_FSM <= RX_RDT;
                end 
            end
            RX_RDT: if(RX_CE)begin // recieve data
                RX_DATA_T[7:0] <= {RXD_RG, RX_DATA_T[7:1]};
                RX_DATA_CT <= RX_DATA_CT + 1'b1;
                if(RX_DATA_CT == 3'h7) RX_FSM <= RX_RPARB;
            end
            RX_RPARB: if(RX_CE) // Recieve parity bit
            begin
                RX_FSM <= RX_RSTB1; 
                RX_DATA_T[8] <= ~(^RX_DATA[7:0]) ^ RXD_RG; // Result of parity check (Odd) (ask about presentation)
            end
            RX_RSTB1: if(RX_CE) // Recieve stop bit 1
            begin
                RX_FSM <= RX_RSTB2;
                RX_DATA_T[9] <= ~RXD_RG; 
            end
            RX_RSTB2: if(RX_CE) // Recieve stop bit 2
            begin
                if(RXD_RG) 
                    begin
                       RX_FSM <= RX_IDLE;
                       RX_DATA_EN <= 1'b1; // I dont really get why (ask later)
                       RXCT_R <= 1'b1; 
                    end    
                else
                    begin
                        RX_FSM <= RX_WEND;
                        RX_DATA_T[9] <= 1'b1;
                    end                     
            end
            RX_WEND: if(RX_CE) // Wait end
            begin
                if(RXD_RG) 
                begin
                    RX_FSM <= RX_IDLE;
                    RX_DATA_EN <= 1'b1;
                    RXCT_R <= 1'b1;
                end
            end
            default:
            begin
                RX_FSM <= RX_IDLE;
                RX_DATA_EN <= 1'b0;
                RX_DATA_T <= 10'd0;
                RX_DATA_CT <= 3'd0;
                RXCT_R <= 1'b1;
            end
        endcase
end         
// TODO: Fix second stop bit in rx and tx fsm.
reg [2:0] TX_FSM;
reg [2:0] TX_DATA_CT;
reg TX_PAR_BIT_RG;
reg [7:0] TX_DATA;
reg TX_RDY_R;
localparam TX_IDLE = 3'd0;
localparam TX_WCE = 3'd1;
localparam TX_TSTRB = 3'd2;
localparam TX_TDT = 3'd3;
localparam TX_TPARB = 3'd4;
localparam TX_TSTB1 = 3'd5;

always @(posedge CLK, posedge RST)
    if (RST) begin
        TX_FSM <= TX_IDLE;
        TX_DATA <= 8'h00;
        TX_PAR_BIT_RG <= 1'b0;
        TX_RDY_R <= 1'b1;
        TX_DATA_CT <= 3'b000;
        TXD <= 1'b1;
        TXCT_R <= 1'b1;
    end
    else
        case (TX_FSM)
            TX_IDLE: if (TX_RDY_T) begin
                TX_DATA <= TX_DATA_R;
                TX_PAR_BIT_RG <= ~(^TX_DATA_R[7:0]);
                TX_RDY_R <= 1'b0;
                if (UART_CE) begin
                    TX_FSM <= TX_TSTRB;
                    TXD <= 1'b0;
                    TXCT_R <= 1'b0;
                end
                else TX_FSM <= TX_WCE;
            end
            TX_WCE: if (UART_CE) begin
                TX_FSM<= TX_TSTRB;
                TXD <= 1'b0;
                TXCT_R <= 1'b0;
            end
            TX_TSTRB: if (TX_CE) begin
                TX_FSM <= TX_TDT;
                TXD <= TX_DATA[0];
                TX_DATA <= {1'b0, TX_DATA[7:1]};
            end
            TX_TDT: if (TX_CE) begin
                TX_DATA <= {1'b0, TX_DATA[7:1]};
                TX_DATA_CT <= TX_DATA_CT + 1'b1;
                if (TX_DATA_CT == 3'd7) begin
                    TX_FSM <= TX_TPARB;
                    TXD <= TX_PAR_BIT_RG;
                end
                else TXD <= TX_DATA[0];
            end
            TX_TPARB: if (TX_CE) begin
                TX_FSM <= TX_TSTB1;
                TXD <= 1'b1;
            end
            TX_TSTB1: if (TX_CE) begin
                TX_FSM <= TX_IDLE;
                TX_RDY_R <= 1'b1;
                TXCT_R <= 1'b1;
            end
            default: begin
                TX_FSM <= TX_IDLE;
                TX_DATA <= 8'h00;
                TX_PAR_BIT_RG <= 1'b0;
                TX_RDY_R <= 1'b1;
                TX_DATA_CT <= 3'b000;
                TXD <= 1'b1;
                TXCT_R <= 1'b1;
            end
        endcase

reg [7:0] UART_CT;

always @(posedge CLK, posedge RST)
    if (RST) begin
        UART_CT <= 8'd0;
        UART_CE <= 1'b0;
    end
    else begin
        if (UART_CT == 8'd163) UART_CT <= 8'd0;
        else UART_CT <= UART_CT + 1'b1;
        UART_CE <= UART_CT == 8'd163;
    end

endmodule
