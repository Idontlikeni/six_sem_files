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
// N = 48 + 3 = 51 Tochno N?
//
// ---------------------------------------------

localparam IDLE = 5'd0;
localparam A_STATE = 5'd1;
localparam D1_STATE = 5'd2;
localparam D2_STATE = 5'd3;
localparam M_STATE = 5'd4;
localparam U_STATE = 5'd5;
localparam L1_STATE = 5'd6;
localparam W_STATE = 5'd7;
localparam R_STATE = 5'd8;
localparam O_STATE = 5'd9;
localparam N_STATE = 5'd10;
localparam F1_STATE = 5'd11;
localparam F2_STATE = 5'd12;
localparam L2_STATE = 5'd13;
localparam E_STATE = 5'd14;
localparam D_STATE = 5'd15;
localparam NUM_8_1_STATE = 5'd16;
localparam NUM_2_STATE = 5'd17;
localparam NUM_0_1_STATE = 5'd18;
localparam NUM_4_STATE = 5'd19;
localparam NUM_0_2_STATE = 5'd20;
localparam UNDERLINE_STATE = 5'd21;
localparam SPACE_STATE = 5'd22;
localparam NUM_8_2_STATE = 5'd23;

// и т.д.
localparam TRANS = 5'd16;
localparam SROPR = 5'd17;
localparam ROPR = 5'd18;
localparam EROPR = 5'd19;
localparam ERCMD = 5'd20;

reg [4:0] FSM_STATE;
reg [3:0] DATA_CT;
reg [3:0] END_CT;
reg OPR2_FLG;
reg [1:0] X40_8_FLG;

wire A_FLG;
wire D_FLG;
wire M_FLG;
wire U_FLG;
wire L_FLG;
wire W_FLG;
wire R_FLG;
wire O_FLG;
wire N_FLG;
wire F_FLG;
wire E_FLG;
wire D_FLG;
wire FLG_0;
wire FLG_2;
wire FLG_4;
wire FLG_8;
wire UNDERLINE_FLG;
wire SPACE_FLG;
wire CR_FLG;
wire LF_FLG;

always @(posedge CLK, posedge RST)
    if (RST) begin
        FSM_STATE <= IDLE;
        CMD_RDY_T <= 1'b0;
        CMD_DATA_T <= 51'd0;
        DATA_CT <= 4'b0; // 48 - max; 48/4 = 12 - num of half-bytes
        END_CT <= 4'h0;
        OPR2_FLG <= 1'b0;
    end
    else begin
        case (FSM_STATE)
            IDLE: if (RX_DATA_EN) begin
                if (A_FLG) FSM_STATE <= A_STATE;
                else if (M_FLG) FSM_STATE <= M_STATE;
                else if (L_FLG) FSM_STATE <= L1_STATE;
                else if (W_FLG) FSM_STATE <= W_STATE;
                else if (O_FLG) FSM_STATE <= O_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // I think I should change this to 50:48
                end
            end
            A_STATE: if (RX_DATA_EN) begin // ADD8
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
                if(FLG_8) FSM_STATE <= NUM_8_1_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            NUM_8_1_STATE: if (RX_DATA_EN) begin
                if (SPACE_FLG) begin
                    FSM_STATE <= SROPR;
                    CMD_DATA_T[50:48] = 3'b001;// 50:48? 
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end

            M_STATE: if (RX_DATA_EN) begin // MUL20
                if (U_FLG) FSM_STATE <= U_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // 50:48? 
                end
            end
            U_STATE: if (RX_DATA_EN) begin
                if (D_FLG) FSM_STATE <= L1_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // 50:48? 
                end
            end
            L1_STATE: if (RX_DATA_EN) begin
                if (FLG_2) FSM_STATE <= NUM_2_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            NUM_2_STATE: if (RX_DATA_EN) begin
                if (FLG_0) FSM_STATE <= NUM_0_1_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            NUM_0_1_STATE: if (RX_DATA_EN) begin
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

            W_STATE: if (RX_DATA_EN) begin
                if (U_FLG) FSM_STATE <= R_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // 50:48? 
                end
            end
            R_STATE: if (RX_DATA_EN) begin
                if (FLG_4) begin
                    FSM_STATE <= NUM_4_STATE;
                    X40_8_FLG = 2'b00; // WR
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end

            O_STATE: if (RX_DATA_EN) begin
                if (N_FLG) FSM_STATE <= N_STATE;
                if (F_FLG) FSM_STATE <= F1_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111; // 50:48? 
                end
            end
            N_STATE: if (RX_DATA_EN) begin
                if (FLG_4) begin
                    FSM_STATE <= NUM_4_STATE;
                    X40_8_FLG <= 2'b01; // ON
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b01;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            F1_STATE: if (RX_DATA_EN) begin
                if(F_FLG) FSM_STATE <= F2_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            F2_STATE: if (RX_DATA_EN) begin
                if (FLG_4) begin
                    FSM_STATE <= NUM_4_STATE;
                    X40_8_FLG <= 2'b10; // OFF
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            L2_STATE: if(RX_DATA_EN) begin
                if(E_FLG) FSM_STATE <= E_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            E_STATE: if(RX_DATA_EN) begin
                if(D_FLG) FSM_STATE <= D_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            D_STATE: if (RX_DATA_EN) begin
                if (FLG_4) begin
                    FSM_STATE <= NUM_4_STATE;
                    X40_8_FLG <= 2'b11; // LED
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            NUM_4_STATE: if(RX_DATA_EN) begin
                if(FLG_0) FSM_STATE <= NUM_0_2_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            NUM_0_2_STATE: if(RX_DATA_EN) begin
                if(UNDERLINE_FLG) FSM_STATE <= UNDERLINE_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            UNDERLINE_STATE: if(RX_DATA_EN) begin
                if(FLG_8) FSM_STATE <= NUM_8_2_STATE;
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;// 50:48? 
                end
            end
            NUM_8_2_STATE: if(RX_DATA_EN) begin
                if (SPACE_FLG) begin
                    FSM_STATE <= SROPR;
                    case(X40_8_FLG)
                        2'b00: CMD_DATA_T[50:48] = 3'b101; // WR
                        2'b01: CMD_DATA_T[50:48] = 3'b100; // ON
                        2'b10: CMD_DATA_T[50:48] = 3'b011; // OFF
                        2'b11: CMD_DATA_T[50:48] = 3'b010; // LED
                    endcase
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
                    CMD_DATA_T[50:0] <= {CMD_DATA_T[46:0], DC_ASCII_HEX}; // what is this
                    DATA_CT <= DATA_CT + 1'b1; // should it even be here
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;
                end
            end
            ROPR: if(RX_DATA_EN) begin
                if (HEX_FLG) begin
                    CMD_DATA_T[50:0] <= {CMD_DATA_T[46:0], DC_ASCII_HEX};
                    if (DATA_CT == END_CT-1) begin // In pres. its just END_CT
                        FSM_STATE <= EROPR;
                        DATA_CT <= 4'b0;
                    end
                    else DATA_CT <= DATA_CT + 1'b1;
                end
                else begin
                    FSM_STATE <= TRANS;
                    CMD_RDY_T <= 1'b1;
                    CMD_DATA_T[50:48] <= 3'b111;
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
                    CMD_DATA_T[50:48] <= 3'b111;
                end
            end
            ERCMD: if (RX_DATA_EN) begin
                FSM_STATE <= TRANS;
                CMD_RDY_T <= 1'b1;
                if (~LF_FLG) CMD_DATA_T[50:48] <= 3'b111;
            end
            TRANS: if (CMD_RDY_R) begin
                FSM_STATE <= IDLE;
                CMD_RDY_T <= 1'b0;
                OPR2_FLG <= 1'b0;
                DATA_CT <= 4'b0;
            end
            default: begin
                FSM_STATE <= IDLE;
                CMD_RDY_T <= 1'b0;
                CMD_DATA_T <= 51'd0;
                DATA_CT <= 4'b0;
                END_CT <= 4'h0;
                OPR2_FLG <= 1'b0;
            end
        endcase
        
        // Формирование END_CT
        case (OPR2_FLG)
            1'b0:
                case (CMD_DATA_T[50:48])
                    3'b000: END_CT <= 4'h5; // MUL20
                    3'b001: END_CT <= 4'h2; // ADD8
                    3'b010: END_CT <= 4'h10; // LED40_8
                    3'b011: END_CT <= 4'h10; // OFF40_8
                    3'b100: END_CT <= 4'h10; // ON40_8
                    3'b101: END_CT <= 4'h10; // WR40_8
                    3'b110: END_CT <= 4'h0; // -
                    default: END_CT <= 4'h0; // Err
                endcase
            1'b1:
                case (CMD_DATA_T[50:48])
                    3'b000: END_CT <= 4'h5;
                    3'b001: END_CT <= 4'h2;
                    3'b010: END_CT <= 4'h2;
                    3'b011: END_CT <= 4'h2;
                    3'b100: END_CT <= 4'h2;
                    3'b101: END_CT <= 4'h2;
                    3'b110: END_CT <= 4'h0;
                    default: END_CT <= 4'h0;
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
assign UNDERLINE_FLG = RX_DATA_R == 8'h5F;
// и т.д.

assign ASCII_DATA = RX_DATA_R;

endmodule
