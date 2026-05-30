
`timescale 1ns / 1ps

module test_analyzer();

reg CLK;
reg RST;
reg RX_DATA_EN;
reg [7:0] RX_DATA_R;
wire [7:0] ASCII_DATA;
wire HEX_FLG;
wire [3:0] DC_ASCII_HEX;
wire CMD_RDY_T;
wire [50:0] CMD_DATA_T;
reg CMD_RDY_R;

localparam CLK_PERIOD = 10;

TT_DC_ASCII_HEX ascii_to_hex (
    .ASCII(RX_DATA_R),
    .HEX(DC_ASCII_HEX),
    .HEX_FLG(HEX_FLG)
);

TT_ANALYZER DUT (
    .CLK(CLK),
    .RST(RST),
    .RX_DATA_EN(RX_DATA_EN),
    .RX_DATA_R(RX_DATA_R),
    .ASCII_DATA(ASCII_DATA),
    .HEX_FLG(HEX_FLG),
    .DC_ASCII_HEX(DC_ASCII_HEX),
    .CMD_RDY_T(CMD_RDY_T),
    .CMD_DATA_T(CMD_DATA_T),
    .CMD_RDY_R(CMD_RDY_R)
);

initial begin
    CLK = 1'b0;
    forever #(CLK_PERIOD/2) CLK = ~CLK;
end

// Отправка символа
task send_char;
    input [7:0] c;
    begin
        @(posedge CLK);
        RX_DATA_R <= c;
        RX_DATA_EN <= 1'b1;
        @(posedge CLK);
        RX_DATA_EN <= 1'b0;
        repeat (5) @(posedge CLK);
    end
endtask

// Отправка строки
task send_string;
    input [7:0] c0, c1, c2, c3, c4, c5, c6;
    begin
        if (c0 != 8'h00) send_char(c0);
        if (c1 != 8'h00) send_char(c1);
        if (c2 != 8'h00) send_char(c2);
        if (c3 != 8'h00) send_char(c3);
        if (c4 != 8'h00) send_char(c4);
        if (c5 != 8'h00) send_char(c5);
        if (c6 != 8'h00) send_char(c6);
    end
endtask

// Отправка пробела
task send_space;
    begin
        send_char(8'h20);
    end
endtask

// Отправка HEX числа (2 цифры = 8 бит)
task send_hex_2;
    input [7:0] value;
    reg [3:0] nibble;
    reg [7:0] ascii;
    integer idx;
    begin
        for (idx = 1; idx >= 0; idx = idx - 1) begin
            nibble = (value >> (idx*4)) & 4'hF;
            if (nibble < 10)
                ascii = 8'h30 + nibble;
            else
                ascii = 8'h41 + (nibble - 10);
            send_char(ascii);
        end
    end
endtask

// Отправка HEX числа (3 цифры = 12 бит)
task send_hex_3;
    input [11:0] value;
    reg [3:0] nibble;
    reg [7:0] ascii;
    integer idx;
    begin
        for (idx = 2; idx >= 0; idx = idx - 1) begin
            nibble = (value >> (idx*4)) & 4'hF;
            if (nibble < 10)
                ascii = 8'h30 + nibble;
            else
                ascii = 8'h41 + (nibble - 10);
            send_char(ascii);
        end
    end
endtask

// Отправка HEX числа (10 цифр = 40 бита)
task send_hex_10;
    input [39:0] value;
    reg [3:0] nibble;
    reg [7:0] ascii;
    integer idx;
    begin
        for (idx = 10; idx >= 0; idx = idx - 1) begin
            nibble = (value >> (idx*4)) & 4'hF;
            if (nibble < 10)
                ascii = 8'h30 + nibble;
            else
                ascii = 8'h41 + (nibble - 10);
            send_char(ascii);
        end
    end
endtask

// Отправка CR+LF
task send_cr_lf;
    begin
        send_char(8'h0D);
        send_char(8'h0A);
    end
endtask

// Ожидание готовности команды
task wait_cmd;
    begin
        while (CMD_RDY_T == 1'b0) begin
            @(posedge CLK);
        end
        @(posedge CLK);
    end
endtask

// Подтверждение приема команды
task ack_cmd;
    begin
        CMD_RDY_R = 1'b1;
        @(posedge CLK);
        CMD_RDY_R = 1'b0;
        @(posedge CLK);
        repeat (10) @(posedge CLK);
    end
endtask

// Вывод результата
task show_result;
    input [2:0] expected_code;
    begin
        $display("CMD_RDY_T = %b", CMD_RDY_T);
        $display("CMD_CODE  = %b", DUT.CMD_DATA_T[50:48]);
        $display("CMD_DATA  = 0x%h", DUT.CMD_DATA_T[47:0]);
        
        if (DUT.CMD_DATA_T[50:48] == expected_code) begin
            $display("PASS: Expected code %b", expected_code);
        end else begin
            $display("FAIL: Expected %b, got %b", expected_code, DUT.CMD_DATA_T[50:48]);
        end
    end
endtask

// Сброс системы
task reset_system;
    begin
        RST = 1'b1;
        RX_DATA_EN = 1'b0;
        RX_DATA_R = 8'h00;
        CMD_RDY_R = 1'b0;
        #100;
        RST = 1'b0;
        #200;
    end
endtask

initial begin
    // ТЕСТ 1. ADD8
    reset_system();
    $display("");
    $display(">>> TEST 1: ADD8 11 10");
    send_string(8'h41, 8'h44, 8'h44, 8'h38, 8'h00, 8'h00, 8'h00); // SUB8
    send_space();
    send_hex_2(8'h11);
    send_space();
    send_hex_2(8'h10);
    send_cr_lf();
    wait_cmd();
    show_result(3'b001);
    ack_cmd();
    
    // ТЕСТ 2. MUL20
    reset_system();
    $display("");
    $display(">>> TEST 2: MUL20 12345 67890");
    send_string(8'h4D, 8'h55, 8'h4C, 8'h32, 8'h30, 8'h00, 8'h00); // MUL20
    send_space();
    send_hex_5(20'h12345);
    send_space();
    send_hex_5(20'h67890);
    send_cr_lf();
    wait_cmd();
    show_result(3'b000);
    ack_cmd();
    
    // ТЕСТ 3. WR40_8
    reset_system();
    $display("");
    $display(">>> TEST 3: WR40_8 1234567890 78");
    send_string(8'h57, 8'h52, 8'h34, 8'h30, 8'h5F, 8'h38, 8'h00); // WR24_8
    send_space();
    send_hex_10(40'h1234567890);
    send_space();
    send_hex_2(8'h78);
    send_cr_lf();
    wait_cmd();
    show_result(3'b101);
    ack_cmd();
    
    // ТЕСТ 4. ON40_8
    reset_system();
    $display("");
    $display(">>> TEST 4: ON40_8 1234ABCDEF 12");
    send_string(8'h4F, 8'h4E, 8'h34, 8'h30, 8'h5F, 8'h38, 8'h00); // ON40_8
    send_space();
    send_hex_10(40'h1234ABCDEF);
    send_space();
    send_hex_2(8'h12);
    send_cr_lf();
    wait_cmd();
    show_result(3'b100);
    ack_cmd();
    
    // ТЕСТ 5. OFF40_8
    reset_system();
    $display("");
    $display(">>> TEST 5: OFF40_8 1234567890 34");
    send_string(8'h4F, 8'h46, 8'h46, 8'h34, 8'h30, 8'h5F, 8'h38); // OFF40_8
    send_space();
    send_hex_10(40'h1234567890);
    send_space();
    send_hex_2(8'h34);
    send_cr_lf();
    wait_cmd();
    show_result(3'b011);
    ack_cmd();
    
    // ТЕСТ 6. LED40_8
    reset_system();
    $display("");
    $display(">>> TEST 6: LED40_8 1234789ABC 56");
    send_string(8'h4C, 8'h45, 8'h44, 8'h34, 8'h30, 8'h5F, 8'h38); // LED40_8
    send_space();
    send_hex_10(40'h1234789ABC);
    send_space();
    send_hex_2(8'h56);
    send_cr_lf();
    wait_cmd();
    show_result(3'b010);
    ack_cmd();
    
    // ТЕСТ 7. ОШИБКА (неизвестная команда)
    reset_system();
    $display("");
    $display(">>> TEST 7: XYZ (unknown command)");
    send_string(8'h58, 8'h59, 8'h5A, 8'h00, 8'h00, 8'h00, 8'h00); // XYZ
    send_cr_lf();
    wait_cmd();
    show_result(3'b001);
    ack_cmd();

    #100;

    $finish;
end

endmodule
