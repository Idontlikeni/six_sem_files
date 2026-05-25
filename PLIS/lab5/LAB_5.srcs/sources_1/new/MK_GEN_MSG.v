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
    input [28:0] RES_DATA_R, // вход принимаемых данных результата
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

reg [1:0] RES_CT; // счетчик символов результата
wire [1:0] CT_MX; // загружаемое значение счетчика RES_CT
reg [6:0] END_ADDR; // значение последнего адреса обращения к ПЗУ
reg [11:0] RES_DATA; // данные результата
reg RES_FLG; // флаг результата выполнения арифметической операции

// FSM
always @(posedge CLK, posedge RST)
    if (RST) begin
        FSM_STATE <= IDLE;
        TX_RDY_T <= 1'b0;
        TX_DATA_T <= 8'd0;
        RES_RDY_R <= 1'b1;
        RES_CT <= 2'b0;
        RES_DATA <= 12'd0;
        RES_FLG <= 1'b0;
        ADDR <= 7'b0;
        END_ADDR <= 7'b0;
    end
    else
        case (FSM_STATE)
            IDLE: if (RES_RDY_T) begin
                FSM_STATE <= TRES;
                RES_RDY_R <= 1'b0;
                ADDR <= RES_DATA_R[25:19];
                END_ADDR <= RES_DATA_R[18:12];
                RES_DATA <= RES_DATA_R[11:0];
                RES_FLG <= RES_DATA_R[28:26] == 3'b100 | RES_DATA_R[28:26] == 3'b010;
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
                if (RES_CT == 2'b11) begin
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
                RES_CT <= 2'b0;
                RES_DATA <= 12'd0;
                RES_FLG <= 1'b0;
                ADDR <= 7'b0;
                END_ADDR <= 7'b0;
            end
        endcase

assign CT_MX = (RES_DATA_R[28:26] == 3'b100) ? 2'b01 : 2'b00;

always@* begin
    case (RES_CT)
        2'b00: HEX_DATA <= RES_DATA[11:8];
        2'b01: HEX_DATA <= RES_DATA[7:4];
        2'b10: HEX_DATA <= RES_DATA[3:0];
        default: HEX_DATA <= 4'h0;
    endcase
end

endmodule