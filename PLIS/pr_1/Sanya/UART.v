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
    input      [7:0] TX_DATA_T,
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
assign TX_CE = UART_CE & TX_SAMP_CT == 4'b1111;

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
                            RX_DATA_T[0] <= 1'd0; // RX_DATA_T[9]?
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
                        RX_FSM <= RX_WEND;
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

    reg [2:0] tx_fsm;
    localparam [2:0] tx_idle =  3'd0;
    localparam [2:0] tx_wce =   3'd1;
    localparam [2:0] tx_tstrb = 3'd2;
    localparam [2:0] tx_tdt =   3'd3;
    localparam [2:0] tx_tparb = 3'd4;
    localparam [2:0] tx_tstb1 = 3'd5;
    reg [7:0] tx_data;
    reg       tx_par_bit_rg;
    reg [2:0] tx_data_ct;
    
    
    reg uart_ce;
    reg [10:0] uart_ct;
    
    always@(posedge CLK, posedge RST) // ????
        if(RST) begin
            uart_ce <= 1'b0;
            uart_ct <= 11'd0;
        end
        else begin
            if(uart_ct == 11'd1301) uart_ct <= 11'd0; // Why 1301?
            else uart_ct <= uart_ct + 1'b1;
            uart_ce <= uart_ct == 11'd1301;
        end
        
    always@(posedge CLK, posedge RST)
        if(RST)begin
            tx_fsm <= tx_idle;
            tx_data <= 8'h00;
            tx_par_bit_rg <= 1'b0;
            TX_RDY_R <= 1'b1;
            tx_data_ct <= 3'd0;
            TXD <= 1'b1;
            TXCT_R <= 1'b1;
        end
        else
            case(tx_fsm)
                tx_idle: if(TX_RDY_R) begin // IDLE (TX_RDY_T in file)
                    tx_data <= TX_DATA_R;
                    tx_par_bit_rg <= ~(^TX_DATA_R); // Parity caclculation result
                    TX_RDY_R <= 1'b0;
                    if(uart_ce) begin
                        tx_fsm <= tx_tstrb;
                        TXD <= 1'b0;
                        TXCT_R <= 1'b0;
                    end
                    else tx_fsm <= tx_wce;
                end
                tx_wce: if(uart_ce) begin // Wait for UART_CE signal
                    tx_fsm <= tx_tstrb;
                    TXD <= 1'b0;
                    TXCT_R <= 1'b0;
                end
                tx_tstrb: if(TX_CE) begin // Transmit start bit
                    tx_fsm <= tx_tstrb;
                    TXD <= tx_data[0];
                    tx_data <= {1'b0, tx_data[7:1]};
                end
                tx_tdt: if(TX_CE) begin // Transmitted data
                    tx_data <= {1'b0, tx_data[7:1]};
                    tx_data_ct <= tx_data_ct + 1'b1;
                    if(tx_data_ct == 3'd7) begin
                        tx_fsm <= tx_tparb;
                        TXD <= tx_par_bit_rg;
                    end
                    else TXD <= tx_data[0];
                end
                
                tx_tparb: if(TX_CE) begin // Transmit parity bit
                    tx_fsm <= tx_tstb1;
                    TXD <= 1'b1;
                end
                tx_tstb1: if(TX_CE) begin // Transmit stop bit 1
                    tx_fsm <= tx_idle;
                    TXD <= 1'b1 // IN file, without last 2 lines (???)
                    TX_RDY_R <= 1'b1;
                    TXCT_R <= 1'b1;
                end
                tx_tstb2: if(TX_CE) begin // Transmit stop bit 2
                    tx_fsm <= tx_idle;
                    TX_RDY_R <= 1'b1;
                    TXCT_R <= 1'b1;
                end
                default: begin
                    tx_fsm <= tx_idle;
                    tx_data <= 8'h00;
                    tx_par_bit_rg <= 1'b0;
                    TX_RDY_R <= 1'b1;
                    tx_data_ct <= 3'd0;
                    TXD <= 1'b1;
                    TXCT_R <= 1'b1;
                end
            endcase
endmodule
// TODO error generator
//      all vars to UPPERCASE
//      Change module names to TU
