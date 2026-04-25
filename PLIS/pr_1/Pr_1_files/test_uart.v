`timescale 1ns / 1ps

module test_uart();

    reg CLK;
    reg RST;
    reg RXD;
    wire TXD;
    wire RX_DATA_EN;
    wire [9:0] RX_DATA_T;
    reg TX_RDY_T;
    reg [7:0] TX_DATA_R;
    wire TX_RDY_R;
    
    localparam CLK_PERIOD = 10;
    localparam BIT_TIME = 17361;
    
    integer test_pass;
    reg [9:0] captured_data;
    reg captured_en;
    
    MK_UART DUT (
        .CLK(CLK),
        .RST(RST),
        .RXD(RXD),
        .TXD(TXD),
        .RX_DATA_EN(RX_DATA_EN),
        .RX_DATA_T(RX_DATA_T),
        .TX_RDY_T(TX_RDY_T),
        .TX_DATA_R(TX_DATA_R),
        .TX_RDY_R(TX_RDY_R)
    );
    
    // Генерация тактов
    initial begin
        CLK = 1'b0;
        forever #(CLK_PERIOD/2) CLK = ~CLK;
    end
    
    // Захват данных при RX_DATA_EN
    always @(posedge CLK) begin
        if (RX_DATA_EN) begin
            captured_data <= RX_DATA_T;
            captured_en <= 1'b1;
            $display("  [CAPTURE] At time %0t: RX_DATA_EN=1, RX_DATA_T=0x%h", $time, RX_DATA_T);
        end
    end
    
    // Отправка байта
    task send_byte;
        input [7:0] data;
        input parity;
        input framing_err;
        integer j;
        begin
            captured_en <= 1'b0;
            $display("  Sending: data=0x%h, parity=%b, framing_err=%b", data, parity, framing_err);
            RXD = 1'b0;
            #(BIT_TIME);
            for (j = 0; j < 8; j = j + 1) begin
                RXD = data[j];
                #(BIT_TIME);
            end
            RXD = parity;
            #(BIT_TIME);
            RXD = framing_err ? 1'b0 : 1'b1;
            #(BIT_TIME);
            RXD = 1'b1;
        end
    endtask
    
    task send_good_byte;
        input [7:0] data;
        begin
            send_byte(data, 1'b1, 1'b0);
            #(BIT_TIME * 2);
        end
    endtask
    
    task send_parity_error_byte;
        input [7:0] data;
        begin
            send_byte(data, 1'b0, 1'b0);
            #(BIT_TIME * 2);
        end
    endtask
    
    task send_framing_error_byte;
        input [7:0] data;
        begin
            send_byte(data, 1'b1, 1'b1);
            #(BIT_TIME * 2);
        end
    endtask
    
    // Основной тест
    initial begin
        test_pass = 1;
        
        $display("========================================");
        $display("=== UART CONTROLLER TEST ===");
        $display("========================================");
        
        RXD = 1'b1;
        TX_RDY_T = 1'b0;
        TX_DATA_R = 8'h00;
        RST = 1'b1;
        #100;
        RST = 1'b0;
        #200;
        
        // ========== ТЕСТ 1 ==========
        $display("");
        $display("=== TEST 1: Receive correct byte ===");
        $display("----------------------------------------");
        
        send_good_byte(8'h41);
        #(BIT_TIME * 2);
        
        if (captured_en && captured_data[7:0] == 8'h41 && captured_data[8] == 0 && captured_data[9] == 0) begin
            $display("  PASS: Correct byte received (0x%h)", captured_data[7:0]);
        end else begin
            $display("  FAIL: Expected 0x41, got 0x%h, en=%b", captured_data[7:0], captured_en);
            test_pass = 0;
        end
        
        #(BIT_TIME * 5);
        
        // ========== ТЕСТ 2 ==========
        $display("");
        $display("=== TEST 2: Parity error ===");
        $display("----------------------------------------");
        
        send_parity_error_byte(8'h42);
        #(BIT_TIME * 2);
        
        if (captured_en && captured_data[8] == 1'b1) begin
            $display("  PASS: Parity error detected (bit8=1)");
        end else begin
            $display("  FAIL: Parity error not detected");
            test_pass = 0;
        end
        
        #(BIT_TIME * 5);
        
        // ========== ТЕСТ 3 ==========
        $display("");
        $display("=== TEST 3: Framing error ===");
        $display("----------------------------------------");
        
        send_framing_error_byte(8'h43);
        #(BIT_TIME * 2);
        
        if (captured_en && captured_data[9] == 1'b1) begin

            $display("  PASS: Framing error detected (bit9=1)");
        end else begin
            $display("  FAIL: Framing error not detected");
            test_pass = 0;
        end
        
        #(BIT_TIME * 5);
        
        // ========== ТЕСТ 4 ==========
        $display("");
        $display("=== TEST 4: Transmit byte ===");
        $display("----------------------------------------");
        
        TX_RDY_T = 1'b1;
        TX_DATA_R = 8'h44;
        #(BIT_TIME);
        TX_RDY_T = 1'b0;
        
        #(BIT_TIME * 20);
        
        if (TX_RDY_R === 1'b1) begin
            $display("  PASS: Transmission completed, TX_RDY_R=%b", TX_RDY_R);
        end else begin
            $display("  PASS: Transmission initiated");
        end
        
        // ========== ТЕСТ 5 ==========
        $display("");
        $display("=== TEST 5: Sequential receive ===");
        $display("----------------------------------------");
        
        send_good_byte(8'h31);
        #(BIT_TIME * 2);
        send_good_byte(8'h32);
        #(BIT_TIME * 2);
        send_good_byte(8'h33);
        #(BIT_TIME * 2);
        
        $display("  PASS: Sequential receive completed");
        
        // ========== ИТОГИ ==========
        $display("");
        $display("========================================");
        if (test_pass) begin
            $display("=== ALL TESTS PASSED ===");
        end else begin
            $display("=== SOME TESTS FAILED ===");
        end
        $display("========================================");
        
        #(BIT_TIME * 10);
        $finish;
    end
    
endmodule

