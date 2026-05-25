`timescale 1ns / 1ps

// Анализатор команд
module ANALYZER(
    // System
    input CLK,
    input RST,
    // UART Data
    input RX_DATA_EN, // вход готовности передачи данных
    input [7:0] RX_DATA_R, // вход принимаемых данных
    // ASCII -> HEX
    output [7:0] ASCII_DATA,
    input HEX_FLG,
    input [3:0] DC_ASCII_HEX,
    // DTP Port
    output reg CMD_RDY_T, // выход готовности передачи команды
    output reg [50:0] CMD_DATA_T, // выход передаваемых данных команды
    input CMD_RDY_R // вход готовности приема команды
);

// ---------------------------------------------
// d1 = 2 * 20 = 40
// d2 = 40 + 8 = 48
// N = 48 + 3 = 51
// log(51) = 6
// ---------------------------------------------

localparam IDLE = 5'd0;
localparam A_STATE = 5'd1;
localparam D1_STATE = 5'd2;
localparam D2_STATE = 5'd3;
localparam M_STATE = 5'd4;
localparam L2_STATE = 5'd5;
// и т.д.
localparam TRANS = 5'd6;
localparam SROPR = 5'd7;
localparam ROPR = 5'd8;
localparam EROPR = 5'd9;
localparam ERCMD = 5'd10;

reg [3:0] FSM_STATE;
reg [2:0] DATA_CT;
reg [2:0] END_CT;
reg OPR2_FLG;

wire A_FLG;
wire D_FLG;
wire M_FLG;
wire L_FLG;

always @(posedge CLK, posedge RST)
    if (RST) begin
        FSM_STATE <= IDLE;
        CMD_RDY_T <= 1'b0;
        CMD_DATA_T <= 51'd0;
        DATA_CT <= 3'b0;
        END_CT <= 3'h0;
        OPR2_FLG <= 1'b0;
    end
    else begin
        case (FSM_STATE)
            IDLE: if (RX_DATA_EN) begin
                if (A_FLG) FSM_STATE <= A_STATE;
                else if (M_FLG) FSM_STATE <= M_STATE;
                else if (L_FLG) FSM_STATE <= L2_STATE;
                else if (W_FLG) FSM_STATE <= L2_STATE;
                else if (O_FLG) FSM_STATE <= L2_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // I think I should change this to 50:48
                end
            end
            A_STATE: if (RX_DATA_EN) begin
                if (D_FLG) FSM_STATE <= D1_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // 50:48? 
                end
            end
            D1_STATE: if (RX_DATA_EN) begin
                if (D_FLG) FSM_STATE <= D2_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // 50:48? 
                end
            end
            D2_STATE: if (RX_DATA_EN) begin
                if (SPACE_FLG) begin
                    FSM_STATE <= SROPR;
                    CMD_DATA_T[50:48] = 3'b000;// 50:48? 
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            // ============
            // и т.д.
            // ============
            SROPR: if(RX_DATA_EN) begin
                if (HEX_FLG) begin
                    FSM_STATE <= ROPR;
                    CMD_DATA_T[31:0] <= {CMD_DATA_T[27:0], DC_ASCII_HEX}; // what is this
                    DATA_CT <= DATA_CT + 1'b1; // should it even be here
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[34:32] <= 3'b111;
                end
            end
            ROPR: if(RX_DATA_EN) begin
                if (HEX_FLG) begin
                    CMD_DATA_T[31:0] <= {CMD_DATA_T[27:0], DC_ASCII_HEX};
                    if (DATA_CT == END_CT-1) begin // In pres. its just END_CT
                        FSM_STATE <= EROPR;
                        DATA_CT <= 3'b0;
                    end
                    else DATA_CT <= DATA_CT + 1'b1;
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[34:32] <= 3'b111;
                end
            end
            EROPR: if (RX_DATA_EN) begin
                if (~OPR2_FLG & SPACE_FLG) begin
                    FSM_STATE <= SROPR;
                    OPR2_FLG <= 1'b1;
                end
                else if (OPR2_FLG & CR_FLG) FSM_STATE <= ERCMD;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[34:32] <= 3'b111;
                end
            end
            ERCMD: if (RX_DATA_EN) begin
                FSM_STATE <= TRANS;
                CMD_RDY_T <= 1'b1;
                if (~LF_FLG) CMD_DATA_T[34:32] <= 3'b111;
            end
            TRANS: if (CMD_RDY_R) begin
                FSM_STATE <= IDLE;
                CMD_RDY_T <= 1'b0;
                OPR2_FLG <= 1'b0;
                DATA_CT <= 3'b0;
            end
            default: begin
                FSM_STATE <= IDLE;
                CMD_RDY_T <= 1'b0;
                CMD_DATA_T <= 35'd0;
                DATA_CT <= 3'b0;
                END_CT <= 3'h0;
                OPR2_FLG <= 1'b0;
            end
        endcase
        
        // Формирование END_CT
        case (OPR2_FLG)
            1'b0:
                case (CMD_DATA_T[34:32])
                    3'b000: END_CT <= 3'h6;
                    3'b001: END_CT <= 3'h0;
                    3'b010: END_CT <= 3'h3;
                    3'b011: END_CT <= 3'h6;
                    3'b100: END_CT <= 3'h2;
                    3'b101: END_CT <= 3'h6;
                    3'b110: END_CT <= 3'h0;
                    default: END_CT <= 3'h6;
                endcase
            1'b1:
                case (CMD_DATA_T[34:32])
                    3'b000: END_CT <= 3'h2;
                    3'b001: END_CT <= 3'h0;
                    3'b010: END_CT <= 3'h3;
                    3'b011: END_CT <= 3'h2;
                    3'b100: END_CT <= 3'h2;
                    3'b101: END_CT <= 3'h2;
                    3'b110: END_CT <= 3'h0;
                    default: END_CT <= 3'h2;
                endcase
        endcase
    end

// Флаги распознаваемых символов
assign A_FLG = RX_DATA_R == 8'h41;
assign D_FLG = RX_DATA_R == 8'h44;
assign M_FLG = RX_DATA_R == 8'h4D;
assign U_FLG = RX_DATA_R == 8'h55;
assign L_FLG = RX_DATA_R == 8'h4C;
assign W_FLG = RX_DATA_R == 8'h57;
assign R_FLG = RX_DATA_R == 8'h52;
assign O_FLG = RX_DATA_R == 8'h4F;
assign N_FLG = RX_DATA_R == 8'h4E;
assign F_FLG = RX_DATA_R == 8'h46;
assign FLG_0 = RX_DATA_R == 8'h50;
assign FLG_2 = RX_DATA_R == 8'h52;
assign FLG_4 = RX_DATA_R == 8'h54;
assign FLG_8 = RX_DATA_R == 8'h58;
assign CR_FLG = RX_DATA_R == 8'h0D;
assign LF_FLG = RX_DATA_R == 8'h0A;
assign SPACE_FLG = RX_DATA_R == 8'h20;
// и т.д.

assign ASCII_DATA = RX_DATA_R;

endmodule
