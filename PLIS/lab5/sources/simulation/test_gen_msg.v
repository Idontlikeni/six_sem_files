`timescale 1ns / 1ps

module test_gen_msg();

reg CLK;
reg RST;
wire TX_RDY_T;
wire [7:0] TX_DATA_T;
reg TX_RDY_R;
reg RES_RDY_T;
reg [36:0] RES_DATA_R;
wire RES_RDY_R;
wire [3:0] HEX_DATA;
wire [7:0] DC_ASCII_DATA;
wire [6:0] ADDR;
wire [7:0] DATA;

localparam CLK_PERIOD = 10;
reg [7:0] received_byte;
integer done;

TT_DC_HEX_ASCII HEX_TO_ASCII (
    .HEX(HEX_DATA),
    .ASCII(DC_ASCII_DATA)
);

TT_ROM ROM (
    .ADDR(ADDR),
    .DATA(DATA)
);

TT_GEN_MSG DUT (
    .CLK(CLK),
    .RST(RST),
    .TX_RDY_T(TX_RDY_T),
    .TX_DATA_T(TX_DATA_T),
    .TX_RDY_R(TX_RDY_R),
    .RES_RDY_T(RES_RDY_T),
    .RES_DATA_R(RES_DATA_R),
    .RES_RDY_R(RES_RDY_R),
    .HEX_DATA(HEX_DATA),
    .DC_ASCII_DATA(DC_ASCII_DATA),
    .ADDR(ADDR),
    .DATA(DATA)
);

initial begin
    CLK = 1'b0;
    forever #(CLK_PERIOD/2) CLK = ~CLK;
end

task send_result;
    input [36:0] result;
    begin
        @(posedge CLK);
        RES_DATA_R <= result;
        RES_RDY_T <= 1'b1;
        $display("CMD_CODE = %b", RES_DATA_T[36:34]);
        $display("START_ADDR = %b", RES_DATA_T[33:27]);
        $display("END_ADDR = %b", RES_DATA_T[26:20]);
        $display("RES_DATA = 0x%h", RES_DATA_T[19:0]);
        @(posedge CLK);
        RES_RDY_T <= 1'b0;
        @(posedge CLK);
    end
endtask

task receive_byte;
    output [7:0] byte_data;
    begin
        while (TX_RDY_T == 1'b0) begin
            @(posedge CLK);
        end
        @(posedge CLK);
        byte_data = TX_DATA_T;
        $display("0x%h ('%c')", byte_data, byte_data);
        TX_RDY_R = 1'b1;
        @(posedge CLK);
        TX_RDY_R = 1'b0;
        @(posedge CLK);
    end
endtask

task read_message;
    begin
        done = 0;
        $display("");
        $display("-- SENT MESSAGE --");
        
        while (done == 0) begin
            receive_byte(received_byte);
            if (received_byte == 8'h0A) begin
                done = 1;
            end
        end
    end
endtask

initial begin
    RST = 1'b1;
    RES_RDY_T = 1'b0;
    RES_DATA_R = 37'd0;
    TX_RDY_R = 1'b0;
    #100;
    RST = 1'b0;
    #100;
    
    // ТЕСТ 1: SUB8
    $display("");
    $display("=== TEST 1: ADD8 ===");
    send_result({3'b100, 7'b0000000, 7'b0001100, 20'h005});
    read_message();
    #200;
    
    // ТЕСТ 2: MUL20
    $display("");
    $display("=== TEST 2: MUL20 ===");
    send_result({3'b010, 7'b0001101, 7'b0011010, 20'h009});
    read_message();
    #200;
    
    // ТЕСТ 3: WR40_8
    $display("");
    $display("=== TEST 3: WR40_8 ===");
    send_result({3'b101, 7'b0011011, 7'b0101000, 20'h000});
    read_message();
    #200;
    
    // ТЕСТ 4: ON40_8
    $display("");
    $display("=== TEST 4: ON40_8 ===");
    send_result({3'b000, 7'b0101001, 7'b0110110, 20'h000});
    read_message();
    #200;
    
    // ТЕСТ 5: OFF40_8
    $display("");
    $display("=== TEST 5: OFF40_8 ===");
    send_result({3'b111, 7'b0110111, 7'b1000101, 20'h000});
    read_message();
    #200;
    
    // ТЕСТ 6: LED40_8
    $display("");
    $display("=== TEST 6: LED40_8 ===");
    send_result({3'b011, 7'b1000110, 7'b1010100, 20'h000});
    read_message();
    #200;
    
    // ТЕСТ 7: ERROR
    $display("");
    $display("=== TEST 7: ERROR ===");
    send_result({3'b001, 7'b1010101, 7'b1100100, 20'h000});
    read_message();
    #200;
    
    $finish;
end
    
endmodule
