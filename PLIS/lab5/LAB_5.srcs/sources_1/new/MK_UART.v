module MK_UART(
    // System
    input CLK, // вход синхросигнала
    input RST, // вход системного сброса
    // UART
    input RXD, // линия приема данных
    output reg TXD, // линия передачи данных
    // STP
    output reg RX_DATA_EN, // выход готовности передачи данных
    output reg [9:0] RX_DATA_T, // выход передаваемых данных
    // DRP
    input TX_RDY_T, // вход готовности передачи данных
    input [7:0] TX_DATA_R, // вход принимаемых данных
    output reg TX_RDY_R // выход готовности приёма данных
);

reg [1:0] RXD_SYNC;
wire RXD_RG; // синхронизированный сигнал RXD

reg UART_CE; // сигнал разрешения синхронизации

// счетчики сэмплов
reg [3:0] RX_SAMP_CT;
reg [3:0] TX_SAMP_CT;

// сигналы синхронного сброса
reg RXCT_R;
reg TXCT_R;

// сигналы разрешения синхронизации
wire TX_CE;
wire RX_CE;

// синхронизатор
always @(posedge CLK, posedge RST)
    if(RST) RXD_SYNC <= 2'b11;
    else RXD_SYNC <= {RXD_SYNC[0], RXD};
assign RXD_RG = RXD_SYNC[1];

// счетчик сэмплов RX (RX_SAMP_CT) (16)
always @(posedge CLK, posedge RST)
    if(RST) RX_SAMP_CT <= 4'h0;
    else if(RXCT_R) RX_SAMP_CT <= 4'h0;
    else if(UART_CE) RX_SAMP_CT <= RX_SAMP_CT + 1'b1;
    assign RX_CE = UART_CE & ~RX_SAMP_CT[3] & RX_SAMP_CT[2] & RX_SAMP_CT[1] & RX_SAMP_CT[0];

// счетчик сэмплов TX (TX_SAMP_CT) (16)
always @(posedge CLK, posedge RST)
    if(RST) TX_SAMP_CT <= 4'h0;
    else if(TXCT_R) TX_SAMP_CT <= 4'h0;
    else if(UART_CE) TX_SAMP_CT <= TX_SAMP_CT + 1'b1;
    assign TX_CE = UART_CE & TX_SAMP_CT[3] & TX_SAMP_CT[2] & TX_SAMP_CT[1] & TX_SAMP_CT[0];

// автомат приема данных RX_FSM
reg [2:0] RX_FSM; // состояние автомата
reg [2:0] RX_DATA_CT; // подсчет количества принимаемых битов данных в кадре 
localparam RX_IDLE = 3'd0; // ожидание стартового бита
localparam RX_RSTRB = 3'd1; // прием стартового бита
localparam RX_RDT = 3'd2; // прием данных
localparam RX_RPARB = 3'd3; // прием бита четности
localparam RX_RSTB1 = 3'd4; // прием певрого стопового бита
localparam RX_WEND = 3'd5; // ожидание конца кадра

always @(posedge CLK, posedge RST)
    if (RST) begin
        RX_FSM <= RX_IDLE;
        RX_DATA_EN <= 1'b0;
        RX_DATA_T <= 10'd0;
        RX_DATA_CT <= 3'd0;
        RXCT_R <= 1'b1;
    end
    else
        case (RX_FSM)
            RX_IDLE: begin
                RX_DATA_EN <= 1'b0;
                if (~RXD_RG) begin
                    RX_FSM <= RX_RSTRB;
                    RX_DATA_T[9] <= 1'b0;
                    RXCT_R <= 1'b0;
                end
            end
            RX_RSTRB: if (RX_CE) begin
                if (RXD_RG) begin
                    RX_FSM <= RX_IDLE;
                    RXCT_R <= 1'b1;
                end
                else RX_FSM <= RX_RDT;
            end
            RX_RDT: if (RX_CE) begin
                RX_DATA_T[7:0] <= {RXD_RG, RX_DATA_T[7:1]};
                RX_DATA_CT <= RX_DATA_CT + 1'b1;
                if (RX_DATA_CT == 3'd7) RX_FSM <= RX_RPARB;
            end
            RX_RPARB: if (RX_CE) begin
                RX_FSM <= RX_RSTB1;
                RX_DATA_T[8] <= ~RXD_RG; // проверка бита четности (Mark)
            end
            RX_RSTB1: if (RX_CE) begin
                if(RXD_RG) begin 
                    RX_FSM <= RX_IDLE;
                    RX_DATA_EN <= 1'b1;
                    RXCT_R <= 1'b1;
                end
                else begin
                    RX_FSM <= RX_WEND;
                    RX_DATA_T[9] <= 1'b1;
                end
            end
            RX_WEND: if(RXD_RG) begin
                RX_FSM <= RX_IDLE;
                RX_DATA_EN <= 1'b1;
                RXCT_R <= 1'b1;
            end
            default: begin
                RX_FSM <= RX_IDLE;
                RX_DATA_EN <= 1'b0;
                RX_DATA_T <= 10'd0;
                RX_DATA_CT <= 3'd0;
                RXCT_R <= 1'b1;
            end
        endcase
    
// автомат передачи данных TX_FSM
reg [2:0] TX_FSM;
reg [2:0] TX_DATA_CT; // подсчет количества передаваемых битов данных в кадре
reg TX_PAR_BIT_RG; // бит четности (1)
reg [7:0] TX_DATA;

localparam TX_IDLE = 3'd0; // ожидание данных
localparam TX_WCE = 3'd1; // ожидание сигнала UART_CE
localparam TX_TSTRB = 3'd2; // передача стартового бита
localparam TX_TDT = 3'd3; // передача данных
localparam TX_TPARB = 3'd4; // преедача бита четности
localparam TX_TSTB1 = 3'd5; // передача первого стопового бита


always @(posedge CLK, posedge RST)
    if (RST) begin
        TX_FSM <= TX_IDLE;
        TX_DATA <= 8'h0;
        TX_PAR_BIT_RG <= 1'b1;
        TX_RDY_R <= 1'b1;
        TX_DATA_CT <= 3'b0;
        TXD <= 1'b1;
        TXCT_R <= 1'b1;
    end
    else
        case (TX_FSM)
            TX_IDLE: if (TX_RDY_T) begin
                TX_DATA <= TX_DATA_R;
                TX_PAR_BIT_RG <= 1'b1;
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
                TX_DATA <= 8'h0;
                TX_PAR_BIT_RG <= 1'b1;
                TX_RDY_R <= 1'b1;
                TX_DATA_CT <= 3'b0;
                TXD <= 1'b1;
                TXCT_R <= 1'b1;
            end
        endcase


// Генерация сигнала разрешения синхронизации UART_CE

// 100.000.000 / 57.600 / 16 = 109

reg [6:0] UART_CT;

always @(posedge CLK, posedge RST)
    if (RST) begin
        UART_CT <= 7'd0;
        UART_CE <= 1'b0;
    end
    else begin
        if (UART_CT == 7'd108) UART_CT <= 7'd0;
        else UART_CT <= UART_CT + 1'b1;
        UART_CE <= UART_CT == 7'd108;
    end
endmodule

