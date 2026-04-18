`timescale 1ns / 1ps

module DMI_FSM(
    input clk,
    input rst,
    // STP (the fuck that means?)
    input RX_DATA_EN,
    input [9:0] RX_DATA_R,
    // DTP (huh?)
    output reg       TX_RDY_T,
    output reg [7:0] TX_DATA_T,
    input            TX_RDY_R,
    // ASCII -> HEX
    output     [7:0] ASCII_DATA,
    input            HEX_FLG,
    input      [3:0] DC_HEX_DATA,
    // HEX -> ASCII
    output reg [3:0] HEX_DATA,
    input      [7:0] DC_ASCII_DATA,
    // Memory_signals
    output reg [6:0] ADDR,// [MEM_WIDHT-1:0]
    input      [7:0] DATA
);
// 28/4 = 7 - кол-во символов, счетчик 3-х разрядный
// 88/4 = 22 - кол-во символов, счетчик 5-разрядный
localparam data_bits = 28;
localparam res_bits = 88;
localparam data_bitness = 3;
localparam res_bitness = 5;

reg [3:0] FSM_STATE;
reg [2:0] DATA_CT;
reg [4:0] RES_CT;
reg [27:0] DATA_REG;
reg [87:0] RES_REG;
reg [6:0] END_ADDR;
reg RES_FLG;

localparam [3:0] IDLE = 0;
localparam [3:0]  RDT = 1;
localparam [3:0]  RCR = 2;
localparam [3:0]  RLF = 3;
localparam [3:0] TRES = 4;
localparam [3:0] TMEM = 5;
localparam [3:0]  TDT = 6;
localparam [3:0]  TCR = 7;
localparam [3:0]  TLF = 8;

localparam [6:0] RES_A0 = 7'b0000000; // Начальный адрес сообщения результата
localparam [6:0] RES_A1 = 7'b0000110; // Последний адрес сообщения результата

reg [6:0] ERR_A0_MX;
reg [6:0] ERR_A1_MX;

// TODO: Рассчитать (см. страницу 30 методчики)
// Рассчитал, но есть подазрение что ошибка четности перепуталас
always @*
    case(RX_DATA_R[9:8])
        2'b00: begin
            ERR_A0_MX <= 7'b0000111;
            ERR_A1_MX <= 7'b0010110;
        end
        2'b01: begin
            ERR_A0_MX <= 7'b0010111;
            ERR_A1_MX <= 7'b0100101;
        end
        2'b10: begin
            ERR_A0_MX <= 7'b0100110;
            ERR_A1_MX <= 7'b0111010;
        end
        default: begin
            ERR_A0_MX <= 7'b0111011;
            ERR_A1_MX <= 7'b1000101;
        end
    endcase

assign ASCII_DATA = RX_DATA_R[7:0];

always @*
    case(RES_CT)
        5'b0000: HEX_DATA [3:0] <= RES_REG[87:84];
        5'b0000: HEX_DATA [3:0] <= RES_REG[83:80];
        5'b0000: HEX_DATA [3:0] <= RES_REG[79:76];
        5'b0000: HEX_DATA [3:0] <= RES_REG[75:72];
        5'b0000: HEX_DATA [3:0] <= RES_REG[71:68];
        5'b0000: HEX_DATA [3:0] <= RES_REG[67:64];
        5'b0000: HEX_DATA [3:0] <= RES_REG[63:60];
        5'b0000: HEX_DATA [3:0] <= RES_REG[59:56];
        5'b0000: HEX_DATA [3:0] <= RES_REG[55:52];
        5'b0000: HEX_DATA [3:0] <= RES_REG[51:48];
        5'b0000: HEX_DATA [3:0] <= RES_REG[47:44];
        5'b0000: HEX_DATA [3:0] <= RES_REG[43:40];
        5'b0000: HEX_DATA [3:0] <= RES_REG[39:36];
        5'b0000: HEX_DATA [3:0] <= RES_REG[35:32];
        5'b0000: HEX_DATA [3:0] <= RES_REG[31:28];
        5'b0000: HEX_DATA [3:0] <= RES_REG[27:24];
        5'b0000: HEX_DATA [3:0] <= RES_REG[23:20];
        5'b0000: HEX_DATA [3:0] <= RES_REG[19:16];
        5'b0000: HEX_DATA [3:0] <= RES_REG[15:12];
        5'b0000: HEX_DATA [3:0] <= RES_REG[11:8];
        5'b0000: HEX_DATA [3:0] <= RES_REG[7:4];
        5'b0000: HEX_DATA [3:0] <= RES_REG[3:0];
        default: HEX_DATA [3:0] <= RES_REG[87:84];
    endcase

// FSM
always @(posedge clk, posedge rst)
    if(rst)
        begin
            FSM_STATE <= IDLE;
            TX_DATA_T <= 8'h00;
            TX_RDY_T <= 1'b0;    
            DATA_CT <= 0; // (разрядность(1'b0))
            RES_CT <= 0;
            DATA_REG <= 1;
            RES_REG <= 0;
            ADDR <= 0;
            END_ADDR <= 0;
            RES_FLG <= 0;
        end
    else
        begin
            case(FSM_STATE)
            IDLE: if(RX_DATA_EN)begin
                if(RX_DATA_R[9] | RX_DATA_R[8] | ~HEX_FLG)begin
                    FSM_STATE <= TRES;
                    ADDR <= ERR_A0_MX;
                    END_ADDR <= ERR_A1_MX;
                end
                else
                begin
                    FSM_STATE <= RDT;
                    ADDR <= RES_A0;
                    END_ADDR <= RES_A1;
                    DATA_REG <= {DATA_REG[data_bits-5:0], DC_HEX_DATA};
                    DATA_CT <= DATA_CT + 1'b1;
                end
            end
            // Recieve Data
            RDT:if(RX_DATA_EN) begin
                if(RX_DATA_R[9] | RX_DATA_R[8] | ~HEX_FLG) begin
                    FSM_STATE <= TRES;
                    ADDR <= ERR_A0_MX;
                    END_ADDR <= ERR_A1_MX;
                end
                else
                begin
                    DATA_REG <= {DATA_REG[data_bits-5:0], DC_HEX_DATA};
                    DATA_CT <= DATA_CT + 1'b1;
                    if(DATA_CT == 27) begin
                        FSM_STATE <= RCR;
                        DATA_CT <= 0; // data_bitness Разраядность'b0
                    end
                end
            end
            // Recieve RC
            RCR:if(RX_DATA_EN) begin
                if(RX_DATA_R[9] | RX_DATA_R[8] | RX_DATA_R[7:0] != 8'h0D)begin
                    FSM_STATE <= TRES;
                    ADDR <= ERR_A0_MX;
                    END_ADDR <= ERR_A1_MX;
                end
                else if(RX_DATA_R[7:0] == 8'h0D)FSM_STATE <= RLF;
            end
            // Recieve LF
            RLF:if(RX_DATA_EN) begin
                if(RX_DATA_R[9] | RX_DATA_R[8] | RX_DATA_R[7:0] != 8'h0A) begin
                    FSM_STATE <= TRES;
                    ADDR <= ERR_A0_MX;
                    END_ADDR <= ERR_A1_MX;
                end
                else if(RX_DATA_R[7:0] == 8'h0A) begin
                    FSM_STATE <= TRES;
                    RES_REG <= RES_REG + DATA_REG; // ЗДЕСЬ И ПОСМОТРЕТЬ РАЗРЯДЫ
                    RES_FLG <= 1'b1;
                end
            end
            // Transmitted result
            TRES:begin
                FSM_STATE <= TMEM;
                TX_DATA_T <= DATA;
                TX_RDY_T  <= 1'b1;
                ADDR      <= ADDR + 1'b1;
            end
            // Transmitted memory
            TMEM: if(TX_RDY_R) begin
                if(ADDR == (END_ADDR + 1'b1)) begin
                    if(RES_FLG) begin
                        FSM_STATE <= TDT;
                        RES_FLG <= 1'b0;
                        TX_DATA_T <= DC_ASCII_DATA;
                        RES_CT <= RES_CT + 1'b1;
                    end
                    else
                        begin
                            FSM_STATE <= TCR;
                            TX_DATA_T <= 8'h0D;
                        end
                end
                else begin
                    TX_DATA_T <= DATA;
                    ADDR <= ADDR + 1'b1;
                end
            end
            // Transmitted data
            TDT:if(TX_RDY_R) begin
                if(RES_CT == 5'd22) begin // insert K (was 3'd7)
                    FSM_STATE <= TCR;
                    TX_DATA_T <= 8'h0D;
                    RES_CT <= 0;
                end
                else
                begin
                    TX_DATA_T <= DC_ASCII_DATA;
                    RES_CT <= RES_CT + 1'b1;
                end
            end
            // Transmitted CR
            TCR:if(TX_RDY_R) begin
                TX_DATA_T <= 8'h0A;
                FSM_STATE <= TLF;
            end
            // Transmitted LF
            TLF:if(TX_RDY_R) begin
                TX_RDY_T <= 1'b0;
                FSM_STATE <= IDLE;
            end
            default: begin
                FSM_STATE <= IDLE;
                TX_DATA_T <= 8'h00;
                TX_RDY_T <= 1'b0;    
                DATA_CT <= 0;
                RES_CT <= 0;
                DATA_REG <= 0;
                RES_REG <= 0;
                ADDR <= 0;
                END_ADDR <= 0;
                RES_FLG <= 0;
            end
            endcase
        end
endmodule
