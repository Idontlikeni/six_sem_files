`timescale 1ns / 1ps

module MK_GEN_MSG(
    // System
    input CLK,
    input RST,
    // UART DTP ODPS
    output reg TX_RDY_T, // выход готовности передачи данных
    output reg [7:0] TX_DATA_T, // выход передаваемых данных
    input TX_RDY_R, // вход готовности приема передаваемых данных
    // RES DRP ODPS
    input RES_RDY_T, // вход готовности передачи результата
    input [36:0] RES_DATA_R, // вход принимаемых данных результата
    output reg RES_RDY_R, // выход готовности приема передаваемых данных результата
    // HEX => ASCII
    output reg [3:0] HEX_DATA,
    input [7:0] DC_ASCII_DATA,
    // ROM
    output reg [6:0] ADDR, // адрес ПЗУ
    input [7:0] DATA // данные ПЗУ по адресу ADDR
);

reg [2:0] FSM_STATE;

localparam IDLE = 3'd0; // Ожидание данных
localparam TRES = 3'd1; // Инициализация передачи данных результата
localparam TMEM = 3'd2; // Передача данных памяти
localparam TDT = 3'd3; // Передача данных результата
localparam TCR = 3'd4; // Передача символа CR
localparam TLF = 3'd5; // Передача символа LF

reg [2:0] RES_CT; // счетчик символов результата
wire [2:0] CT_MX; // загружаемое значение счетчика RES_CT
reg [6:0] END_ADDR; // значение последнего адреса обращения к ПЗУ
reg [19:0] RES_DATA; // данные результата why 12 bits tho, in pres it is 16
reg RES_FLG; // флаг результата выполнения арифметической операции

// FSM
always @(posedge CLK, posedge RST)
    if (RST) begin
        FSM_STATE <= IDLE;
        TX_RDY_T <= 1'b0;
        TX_DATA_T <= 8'd0;
        RES_RDY_R <= 1'b1;
        RES_CT <= 3'b0;
        RES_DATA <= 20'd0;
        RES_FLG <= 1'b0;
        ADDR <= 7'b0;
        END_ADDR <= 7'b0;
    end
    else
        case (FSM_STATE)
            IDLE: if (RES_RDY_T) begin
                FSM_STATE <= TRES;
                RES_RDY_R <= 1'b0;
                ADDR <= RES_DATA_R[33:27]; // [36:34] (k-1:k-3) () () [19:0](k-2n-6:0) 19 = k - 2n - 6 -> 25 = 37 - 2n -> -12 = -2n -> n = 6,k = 37
                END_ADDR <= RES_DATA_R[26:20];
                RES_DATA <= RES_DATA_R[19:0];
                RES_FLG <= RES_DATA_R[36:34] == 3'b001 | RES_DATA_R[36:34] == 3'b000;
                RES_CT <= CT_MX;
            end
            TRES: begin
                FSM_STATE <= TMEM;
                TX_RDY_T <= 1'b1;
                TX_DATA_T <= DATA;
                ADDR <= ADDR + 1'b1;
            end
            TMEM: if (TX_RDY_R) begin
                if (ADDR == (END_ADDR + 1)) begin
                    if (RES_FLG) begin
                        FSM_STATE <= TDT;
                        RES_FLG <= 1'b0;
                        TX_DATA_T <= DC_ASCII_DATA;
                        RES_CT <= RES_CT + 1'b1;
                    end
                    else begin
                        FSM_STATE <= TCR;
                        TX_DATA_T <= 8'h0D;
                    end
                end
                else begin
                    TX_DATA_T <= DATA;
                    ADDR <= ADDR + 1'b1;
                end
            end
            TDT: if (TX_RDY_R) begin
                if (RES_CT == 3'b100) begin // ???? (~|RES_CT)
                    FSM_STATE <= TCR;
                    TX_DATA_T <= 8'h0D;
                end
                else begin
                    TX_DATA_T <= DC_ASCII_DATA;
                    RES_CT <= RES_CT + 1'b1;
                end
            end
            TCR: if (TX_RDY_R) begin
                FSM_STATE <= TLF;
                TX_DATA_T <= 8'h0A;
            end
            TLF: if (TX_RDY_R) begin
                FSM_STATE <= IDLE;
                TX_RDY_T <= 1'b0;
                RES_RDY_R <= 1'b1;
            end
            default: begin
                FSM_STATE <= IDLE;
                TX_RDY_T <= 1'b0;
                TX_DATA_T <= 8'd0;
                RES_RDY_R <= 1'b1;
                RES_CT <= 3'b0;
                RES_DATA <= 20'd0;
                RES_FLG <= 1'b0;
                ADDR <= 7'b0;
                END_ADDR <= 7'b0;
            end
        endcase

assign CT_MX = (RES_DATA_R[36:34] == 3'b001) ? 3'b011 : 3'b00; // Err or smth [19:16] [15:12] [11:8] [7:4] [3:0]

always@* begin
    case (RES_CT) // Not sure about RES_CT - 2 bit or 3 bit 
        3'b000: HEX_DATA <= RES_DATA[19:16];
        3'b001: HEX_DATA <= RES_DATA[15:12];
        3'b010: HEX_DATA <= RES_DATA[11:8];
        3'b011: HEX_DATA <= RES_DATA[7:4];
        3'b100: HEX_DATA <= RES_DATA[3:0];
        default: HEX_DATA <= 4'h0;
    endcase
end

endmodule
