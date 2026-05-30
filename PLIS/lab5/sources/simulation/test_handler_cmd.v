`timescale 1ns / 1ps

module test_handler();

reg CLK;
reg RST;
reg CMD_RDY_T;
reg [50:0] CMD_DATA_R;
wire CMD_RDY_R;
wire S_EX_REQ;
wire [39:0] S_ADDR;
wire [2:0] S_CMD;
wire [7:0] S_D_WR;
reg S_EX_ACK;
reg [7:0] S_D_RD;
wire RES_RDY_T;
wire [36:0] RES_DATA_T;
reg RES_RDY_R;

localparam CLK_PERIOD = 10;

TT_HANDLER_CMD DUT (
    .CLK(CLK),
    .RST(RST),
    .CMD_RDY_T(CMD_RDY_T),
    .CMD_DATA_R(CMD_DATA_R),
    .CMD_RDY_R(CMD_RDY_R),
    .S_EX_REQ(S_EX_REQ),
    .S_ADDR(S_ADDR),
    .S_CMD(S_CMD),
    .S_D_WR(S_D_WR),
    .S_EX_ACK(S_EX_ACK),
    .S_D_RD(S_D_RD),
    .RES_RDY_T(RES_RDY_T),
    .RES_DATA_T(RES_DATA_T),
    .RES_RDY_R(RES_RDY_R)
);

initial begin
    CLK = 1'b0;
    forever #(CLK_PERIOD/2) CLK = ~CLK;
end

// Отправка команды
task send_cmd;
    input [50:0] cmd;
    begin
        @(posedge CLK);
        CMD_DATA_R <= cmd;
        CMD_RDY_T <= 1'b1;
        $display("CMD_CODE = %b", cmd[50:48]);
        $display("CMD_DATA = 0x%h", cmd[47:0]);
        @(posedge CLK);
        CMD_RDY_T <= 1'b0;
    end
endtask

// Ожидание результата
task wait_res;
    begin
        while (RES_RDY_T == 1'b0) begin
            @(posedge CLK);
        end
        @(posedge CLK);
        $display("");
        $display("--- RESULT ---");
        $display("RES_RDY_T = %b", RES_RDY_T);
        $display("RES_TYPE = %b", RES_DATA_T[36:34]);
        $display("START_ADDR = %b", RES_DATA_T[33:27]);
        $display("END_ADDR = %b", RES_DATA_T[26:20]);
        $display("RES_DATA = 0x%h", RES_DATA_T[19:0]);
    end
endtask

// Подтверждение
task ack_res;
    begin
        RES_RDY_R = 1'b1;
        @(posedge CLK);
        RES_RDY_R = 1'b0;
        @(posedge CLK);
    end
endtask

// Симуляция для WR24_8
task bus_response;
    input [7:0] rd_data;
    begin
        while (S_EX_REQ == 1'b0) begin
            @(posedge CLK);
        end
        $display("");
        $display("- BUS OPERATION -");
        $display("S_ADDR = 0x%h, S_CMD = %b, S_D_WR = 0x%h", S_ADDR, S_CMD, S_D_WR);
        S_EX_ACK <= 1'b1;
        S_D_RD <= rd_data;
        @(posedge CLK);
        S_EX_ACK <= 1'b0;
    end
endtask

// Симуляция для ON40_8 и OFF40_8
task led_response;
    input [7:0] rd_data;
    begin
        while (!(S_CMD == 3'b100)) @(posedge CLK); // ???
        $display("");
        $display("- IORD -");
        $display("S_ADDR = 0x%h, S_D_RD = %b", S_ADDR, rd_data);
        S_EX_ACK = 1'b1;
        S_D_RD = rd_data;
        @(posedge CLK);
        S_EX_ACK = 1'b0;
        while (!(S_CMD == 3'b000)) @(posedge CLK); // ???
        $display("");
        $display("- IOWR -");
        $display("S_D_WR = %b", S_D_WR);
        S_EX_ACK = 1'b1;
        @(posedge CLK);
        S_EX_ACK = 1'b0;
    end
endtask

initial begin
    RST = 1'b1;
    CMD_RDY_T = 1'b0;
    CMD_DATA_R = 50'd0;
    S_EX_ACK = 1'b0;
    S_D_RD = 8'h00;
    RES_RDY_R = 1'b0;
    #100;
    RST = 1'b0;
    #100;
    
    // Тест 1. ADD8
    $display("");
    $display("=== TEST 1 ===");
    $display("Command: ADD8 0x9 0x4");
    send_cmd({3'b100, 32'b0, 8'h9, 8'h4});
    wait_res();
    ack_res();
    #200;
    
    // Тест 2. MUL20
    $display("");
    $display("");
    $display("=== TEST 2 ===");
    $display("Command: MUL20 0x2 0x3");
    send_cmd({3'b010, 8'b0, 20'h002, 20'h003});
    wait_res();
    ack_res();
    #200;
    
    // Тест 3. WR40_8
    $display("");
    $display("");
    $display("=== TEST 3 ===");
    $display("Command: WR40_8 0x123456 0x78");
    send_cmd({3'b101, 40'h123456, 8'h78});
    fork
        bus_response(8'h00);
        wait_res();
    join
    ack_res();
    #200;
    
    // Тест 4. ON40_8
    $display("");
    $display("");
    $display("=== TEST 4 ===");
    $display("Command: ON40_8 0xABCDEF 0x12");
    send_cmd({3'b000, 40'hABCDEF, 8'h12});
    fork
        led_response(8'hAA);
        wait_res();
    join
    ack_res();
    #200;
    
    // Тест 5. OFF40_8
    $display("");
    $display("");
    $display("=== TEST 5 ===");
    $display("Command: OFF40_8 0x123456 0x34");
    send_cmd({3'b111, 40'h123456, 8'h34});
    fork
        led_response(8'h55);
        wait_res();
    join
    ack_res();
    #200;
    
    // Тест 6. LED40_8
    $display("");
    $display("");
    $display("=== TEST 6 ===");
    $display("Command: LED40_8 0x789ABC 0x56");
    send_cmd({3'b011, 40'h789ABC, 8'h56});
    fork
        bus_response(8'h00); // ???
        wait_res();
    join
    ack_res();
    #200;
    
    // Тест 7. Ошибка
    $display("");
    $display("");
    $display("=== TEST 7 ===");
    $display("Command: UNKNOWN COMMAND");
    send_cmd({3'b001, 32'd0});
    wait_res();
    ack_res();
    $display("");
    #200;

    $finish;
end
    
endmodule
