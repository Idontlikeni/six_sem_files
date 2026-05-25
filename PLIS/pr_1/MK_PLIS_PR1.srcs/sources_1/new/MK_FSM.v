`timescale 1ns / 1ps

module MK_FSM(
    // System
    input CLK,
    input RST,
    // STP
    input RX_DATA_EN, // вход готовности приема данных
    input [9:0] RX_DATA_R, // вход принимаемых данных
    // DTP
    output reg TX_RDY_T, // выход готовности передачи данных
    output reg [7:0] TX_DATA_T, // выход передаваемых данных
    input TX_RDY_R, // вход готовности приема передаваемых данных
    // ASCII => HEX
    output [7:0] ASCII_DATA, // выход данных ASCII
    input HEX_FLG, // вход флага шестнадцатеричного числа
    input [3:0] DC_HEX_DATA, // вход шестнадцатеричного числа
    // HEX => ASCII
    output reg [3:0] HEX_DATA, // выход шестнадцатеричного числа
    input [7:0] DC_ASCII_DATA, // вход данных ASCII
    // ROM
    output reg [6:0] ADDR, // регистр, хранящий адрес, по которому обращаются к ПЗУ
    input [7:0] DATA // данные ПЗУ по адресу ADDR
);
// разрядность принимаемых данных 108 битов, т.е. 27 символов, т.е. кол-во принимаемых полубайтов => разрядность DATA_CT = 5
// разрядность результата 124 бита, т.е. 31 символ / разрядность RES_CT = 5
// CR => 0x0D
// LF => 0x0A

// FSM
reg [3:0] FSM_STATE; // состояние автомата
reg [4:0] DATA_CT; // счетчик принимаемых полубайтов | upd
reg [4:0] RES_CT; // счетчик передаваемых полубайтов регистра результата | upd
reg [107:0] DATA_REG; // сдвиговый регистр, хранящий принимаемые данные | upd
reg [123:0] RES_REG; // внутренний регистр результата | upd
reg [6:0] END_ADDR; // регистр, хранящий последний адрес, по которому обращаются к ПЗУ
reg RES_FLG; // флаг вывода результата выполнения операции
localparam [3:0] IDLE = 4'd0; // ожидание данных
localparam [3:0] RDT = 4'd1; // прием данных
localparam [3:0] RCR = 4'd2; // прием символа CR
localparam [3:0] RLF = 4'd3; // прием символа LF
localparam [3:0] TRES = 4'd4; // инициализация передачи результата
localparam [3:0] TMEM = 4'd5; // передача данных памяти
localparam [3:0] TDT = 4'd6; // передача данных результата
localparam [3:0] TCR = 4'd7; // передача символа CR
localparam [3:0] TLF = 4'd8; // передача символа LF
localparam [6:0] RES_A0 = 7'b0000000; // начальный адрес сообщения результата в ПЗУ
localparam [6:0] RES_A1 = 7'b0000111; // конечный адрес сообщения результата в ПЗУ

reg [6:0] ERR_A0_MX; // начальный адрес сообщения ошибки в ПЗУ
reg [6:0] ERR_A1_MX; // конечный адрес сообщения ошибки в ПЗУ

always @*
    case (RX_DATA_R[9:8]) // upd
        2'b00: begin // error format data | ошибка формата операнда
            ERR_A0_MX <= 7'b0001000;
            ERR_A1_MX <= 7'b0010110;
        end
        2'b01: begin // error parity | ошибка четности
            ERR_A0_MX <= 7'b0010111;
            ERR_A1_MX <= 7'b0101000;
        end
        2'b10: begin // error format | ошибка формата кадра
            ERR_A0_MX <= 7'b0101001;
            ERR_A1_MX <= 7'b0111101;
        end
        default: begin // 2'b11 | error parity and format | ошибка формата и четности
            ERR_A0_MX <= 7'b0111110;
            ERR_A1_MX <= 7'b1000101;
        end
    endcase

assign ASCII_DATA = RX_DATA_R[7:0];

always @*
    case (RES_CT) // upd
        5'd0: HEX_DATA <= RES_REG[123:120];
        5'd1: HEX_DATA <= RES_REG[119:116];
        5'd2: HEX_DATA <= RES_REG[115:112];
        5'd3: HEX_DATA <= RES_REG[111:108];
        5'd4: HEX_DATA <= RES_REG[107:104];
        5'd5: HEX_DATA <= RES_REG[103:100];
        5'd6: HEX_DATA <= RES_REG[99:96];
        5'd7: HEX_DATA <= RES_REG[95:92];
        5'd8: HEX_DATA <= RES_REG[91:88];
        5'd9: HEX_DATA <= RES_REG[87:84];
        5'd10: HEX_DATA <= RES_REG[83:80];
        5'd11: HEX_DATA <= RES_REG[79:76];
        5'd12: HEX_DATA <= RES_REG[75:72];
        5'd13: HEX_DATA <= RES_REG[71:68];
        5'd14: HEX_DATA <= RES_REG[67:64];
        5'd15: HEX_DATA <= RES_REG[63:60];
        5'd16: HEX_DATA <= RES_REG[59:56];
        5'd17: HEX_DATA <= RES_REG[55:52];
        5'd18: HEX_DATA <= RES_REG[51:48];
        5'd19: HEX_DATA <= RES_REG[47:44];
        5'd20: HEX_DATA <= RES_REG[43:40];
        5'd21: HEX_DATA <= RES_REG[39:36];
        5'd22: HEX_DATA <= RES_REG[35:32];
        5'd23: HEX_DATA <= RES_REG[31:28];
        5'd24: HEX_DATA <= RES_REG[27:24];
        5'd25: HEX_DATA <= RES_REG[23:20];
        5'd26: HEX_DATA <= RES_REG[19:16];
        5'd27: HEX_DATA <= RES_REG[15:12];
        5'd28: HEX_DATA <= RES_REG[11:8];
        5'd29: HEX_DATA <= RES_REG[7:4];
        default: HEX_DATA <= RES_REG[3:0];
    endcase
    

always @(posedge CLK, posedge RST)
    if (RST) begin
        FSM_STATE <= IDLE;
        TX_DATA_T <= 8'h0;
        TX_RDY_T <= 1'b0;
        DATA_CT <= 5'b0; // upd
        RES_CT <= 5'b0; // upd
        DATA_REG <= 108'd0; // upd
        RES_REG <= {124{1'b1}}; // upd
        ADDR <= 7'd0;
        END_ADDR <= 7'd0;
        RES_FLG <= 1'b0;
    end
    else case(FSM_STATE)
        IDLE: if (RX_DATA_EN) begin
            if (RX_DATA_R[9] | RX_DATA_R[8] | ~HEX_FLG) begin
                FSM_STATE <= TRES;
                ADDR <= ERR_A0_MX;
                END_ADDR <= ERR_A1_MX;
            end
            else begin
                FSM_STATE <= RDT;
                ADDR <= RES_A0;
                END_ADDR <= RES_A1;
                DATA_REG <= {DATA_REG[103:0], DC_HEX_DATA}; // upd
                DATA_CT <= DATA_CT + 1'b1;
            end
        end
        RDT: if (RX_DATA_EN) begin
            if (RX_DATA_R[9] | RX_DATA_R[8] | ~HEX_FLG) begin
                FSM_STATE <= TRES;
                ADDR <= ERR_A0_MX;
                END_ADDR <= ERR_A1_MX;
            end
            else begin
                DATA_REG <= {DATA_REG[103:0], DC_HEX_DATA};
                DATA_CT <= DATA_CT + 1'b1;
                if (DATA_CT == 5'd26) begin // upd | 108/4-1=26
                    FSM_STATE <= RCR;
                    DATA_CT <= 5'b0;
                end
            end
        end
        RCR: if (RX_DATA_EN) begin
            if (RX_DATA_R[9] | RX_DATA_R[8] | RX_DATA_R != 8'h0D) begin
                FSM_STATE <= TRES;
                ADDR <= ERR_A0_MX;
                END_ADDR <= ERR_A1_MX;
            end
            else FSM_STATE <= RLF;
        end
        RLF: if (RX_DATA_EN) begin
            if (RX_DATA_R[9] | RX_DATA_R[8] | RX_DATA_R != 8'h0A) begin
                FSM_STATE <= TRES;
                ADDR <= ERR_A0_MX;
                END_ADDR <= ERR_A1_MX;
            end
            else if (RX_DATA_R[7:0] == 8'h0A) begin
                FSM_STATE <= TRES;
                RES_REG <= RES_REG - DATA_REG; // upd ВЫЧИТАНИЕ
                RES_FLG <= 1'b1;
            end
        end
        TRES: begin
            FSM_STATE <= TMEM;
            TX_DATA_T <= DATA;
            TX_RDY_T <= 1'b1;
            ADDR <= ADDR + 1'b1;
        end
        TMEM: if (TX_RDY_R) begin
            if (ADDR == (END_ADDR + 1'b1)) begin
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
            if (RES_CT == 5'd31) begin // upd | 124/4=31
                FSM_STATE <= TCR;
                TX_DATA_T <= 8'h0D;
                RES_CT <= 5'b0;
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
        end
        default: begin
            FSM_STATE <= IDLE;
            TX_DATA_T <= 8'h0;
            TX_RDY_T <= 1'b0;
            DATA_CT <= 5'b0;
            RES_CT <= 5'b0;
            DATA_REG <= 108'd0;
            RES_REG <= 124'd0;
            ADDR <= 7'd0;
            END_ADDR <= 7'd0;
            RES_FLG <= 1'b0;
        end
    endcase
endmodule
