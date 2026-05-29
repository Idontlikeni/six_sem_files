`timescale 1ns / 1ps

// Îáðàáîò÷èê êîìàíä
module MK_HANDLER_CMD(
    // System
    input CLK,
    input RST,
    // DRP ODPS
    input CMD_RDY_T, // âõîä ãîòîâíîñòè ïåðåäà÷è äàííûõ
    input [50:0] CMD_DATA_R, // âõîä ïðèíèìàåìûõ äàííûõ êîìàíäû
    output reg CMD_RDY_R, // âûõîä ãîòîâíîñòè ïðèåìà êîìàíäû
    // STI 1.0
    output reg S_EX_REQ, // âûõîä çàïðîñà èíèöèàòîðà
    output reg [39:0] S_ADDR, // âûõîä àäðåñà èíèöèàòîðà gleb.py
    output reg [2:0] S_CMD, // âûõîä êîìàíäû èíèöèàòîðà
    output reg [7:0] S_D_WR, // âûõîä äàííûõ äëÿ çàïèñè èíèöèàòîðà
    input S_EX_ACK, // âõîä ïîäòâåðæäåíèÿ èíèöèàòîðà
    input [7:0] S_D_RD, // âõîä äàííûõ ÷òåíèÿ èíèöèàòîðà
    // DTP ODPS
    output reg RES_RDY_T, // âûõîä ãîòîâíîñòè ïåðåäà÷è ðåçóëüòàòà
    output [36:0] RES_DATA_T, // âûõîä ïåðåäàâàåìûõ äàííûõ ðåçóëüòàòà [2:0] + 2 * [6:0] + [19:0] = 3 + 2 * 7 + 20 = 37
    input RES_RDY_R // âõîä ãîòîâíîñòè ïðèåìà ðåçóëüòàòà
);

localparam [2:0] WDATA = 3'd0; // Îæèäàíèå äàííûõ
localparam [2:0] ALZ = 3'd1; // Àíàëèç êîìàíäû
localparam [2:0] WR = 3'd2; // Çàïèñü â àäðåñíîå ïðîñòðàíñòâî
localparam [2:0] IORD = 3'd3; // ×òåíèå ïðîñòðàíñòâà ââîäà-âûâîäà
localparam [2:0] IOWR = 3'd4; // Çàïèñü â ïðîñòðàíñòâî ââîäà-âûâîäà
localparam [2:0] TRANS = 3'd5; // Ïåðåäà÷à ðåçóëüòàòà

reg [2:0] FSM_STATE; // ñîñòîÿíèå àâòîìàòà
reg [50:0] CMD_DATA; // ñîõðàíåííûå äàííûå êîìàíäû
reg [19:0] RES_DATA; // äàííûå ðåçóëüòàòà
reg [6:0] START_ADDR; // àäðåñ íà÷àëüíîãî ñèìâîëà ñîîáùåíèÿ
reg [6:0] END_ADDR; // àäðåñ ïîñëåäíåãî ñèìâîëà ñîîáùåíèÿ

// 100 символов, вроде хватает

// FSM
always @(posedge CLK, posedge RST)
    if (RST) begin
        FSM_STATE <= WDATA;
        CMD_DATA <= 51'd0;
        CMD_RDY_R <= 1'b1;
        RES_RDY_T <= 1'b0;
        RES_DATA <= 20'd0;
        S_EX_REQ <= 1'b0;
        S_ADDR <= 40'd0;
        S_CMD <= 3'b0;
        S_D_WR <= 8'd0;
        
    end
    else
        case (FSM_STATE)
            WDATA: if (CMD_RDY_T) begin
                FSM_STATE <= ALZ;
                CMD_DATA <= CMD_DATA_R;
                CMD_RDY_R <= 1'b0;
            end
            ALZ:
                if (CMD_DATA[50:48] == 3'b001) begin // ADD
                    FSM_STATE <= TRANS;
                    RES_DATA <= CMD_DATA[15:8] + CMD_DATA[7:0];
                    RES_RDY_T <= 1'b1;
                end
                else if (CMD_DATA[50:48] == 3'b000) begin // MUL
                    FSM_STATE <= TRANS;
                    RES_DATA <= CMD_DATA[39:20] * CMD_DATA[19:0];
                    RES_RDY_T <= 1'b1;
                end
                else if (CMD_DATA[50:48] == 3'b111) begin // Error
                    FSM_STATE <= TRANS;
                    RES_RDY_T <= 1'b1;
                end
                else if (CMD_DATA[50:48] == 3'b101) begin // WR
                    FSM_STATE <= WR;
                    S_EX_REQ <= 1'b1;
                    S_ADDR <= CMD_DATA[47:8];
                    S_CMD <= 3'b001; // ????
                    S_D_WR <= CMD_DATA[7:0];
                end
                else if (CMD_DATA[50:48] == 3'b010) begin // LED
                    FSM_STATE <= WR;
                    S_EX_REQ <= 1'b1;
                    S_ADDR <= CMD_DATA[47:8];
                    S_CMD <= 3'b000; // ??????
                    S_D_WR <= CMD_DATA[7:0];
                end
                else if (CMD_DATA[50:48] == 3'b100 | CMD_DATA[50:48] == 3'b011) begin // ON | OFF
                    FSM_STATE <= IORD;
                    S_EX_REQ <= 1'b1;
                    S_ADDR <= CMD_DATA[47:8];
                    S_CMD <= 3'b100;
                end
            IORD: if (S_EX_ACK) begin
                FSM_STATE <= IOWR;
                S_CMD <= 3'b000;
                if (CMD_DATA[50:48] == 3'b100) // ON
                    S_D_WR <= S_D_RD | CMD_DATA[7:0];
                if (CMD_DATA[50:48] == 3'b011) // OFF
                    S_D_WR <= S_D_RD & (~CMD_DATA[7:0]);
            end
            IOWR: if (S_EX_ACK) begin
                FSM_STATE <= TRANS;
                S_EX_REQ <= 1'b0;
                RES_RDY_T <= 1'b1;
            end
            WR: if (S_EX_ACK) begin
                FSM_STATE <= TRANS;
                S_EX_REQ <= 1'b0;
                RES_RDY_T <= 1'b1;
            end
            TRANS: if (RES_RDY_R) begin
                FSM_STATE <= WDATA;
                RES_RDY_T <= 1'b0;
                CMD_RDY_R <= 1'b1;
            end
            default: begin
                FSM_STATE <= WDATA;
                CMD_DATA <= 51'd0;
                CMD_RDY_R <= 1'b1;
                RES_RDY_T <= 1'b0;
                RES_DATA <= 20'd0;
                S_EX_REQ <= 1'b0;
                S_ADDR <= 40'd0;
                S_CMD <= 3'b0;
                S_D_WR <= 8'd0;
            end
        endcase

// Êîìáèíàöèîííûå ñõåìû
always@* begin
    // Ôîðìèðîâàíèå START_ADDR
    case (CMD_DATA[50:48])
        3'b001: START_ADDR <= 7'b0000000; // ADD
        3'b000: START_ADDR <= 7'b0001101; // MUL
        3'b101: START_ADDR <= 7'b0011011; // WR
        3'b100: START_ADDR <= 7'b0101001; // ON
        3'b011: START_ADDR <= 7'b0110111; // OFF
        3'b010: START_ADDR <= 7'b1000110; // LED
        3'b111: START_ADDR <= 7'b1010101; // Err
        default: START_ADDR <= 7'b1010101; // ????
    endcase
    // Ôîðìèðîâàíèå END_ADDR
    case (CMD_DATA[50:48])
        3'b000: END_ADDR <= 7'b0001100;
        3'b001: END_ADDR <= 7'b0011010;
        3'b010: END_ADDR <= 7'b0101000;
        3'b011: END_ADDR <= 7'b0110110;
        3'b100: END_ADDR <= 7'b1000101;
        3'b101: END_ADDR <= 7'b1010100;
        3'b110: END_ADDR <= 7'b1100100;
        default: END_ADDR <= 7'b1000101; // ????
    endcase
end

// Ôîðìèðîâàíèå RES_DATA_T
assign RES_DATA_T[36:0] = {CMD_DATA[50:48], START_ADDR[6:0], END_ADDR[6:0], RES_DATA[19:0]};

endmodule
