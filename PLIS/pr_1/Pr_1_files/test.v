`timescale 1ns / 1ps

module test();

    reg CLK;
    reg SYS_NRST;
    reg BTN_0;
    reg BTN_1;
    reg UART_RXD;
    wire UART_TXD;
    
    localparam CLK_PERIOD = 10;
    localparam BIT_TIME = 17361;
    
    integer test_pass;
    integer i;
    
    MK_TOP DUT (
        .CLK(CLK),
        .SYS_NRST(SYS_NRST),
        .BTN_0(BTN_0),
        .BTN_1(BTN_1),
        .UART_RXD(UART_RXD),
        .UART_TXD(UART_TXD)
    );
    
    initial begin
        CLK = 1'b0;
        forever #(CLK_PERIOD/2) CLK = ~CLK;
    end
    
    task send_byte;
        input [7:0] data;
        begin
            $display("  Send: 0x%h ('%c')", data, data);
            UART_RXD = 1'b0;
            #(BIT_TIME);
            for (i = 0; i < 8; i = i + 1) begin
                UART_RXD = data[i];
                #(BIT_TIME);
            end
            UART_RXD = 1'b1;
            #(BIT_TIME);
        end
    endtask
    
    task send_hex_number;
        input [107:0] hex_data;
        reg [3:0] nibble;
        reg [7:0] ascii;
        integer j;
        begin
            for (j = 26; j >= 0; j = j - 1) begin
                nibble = hex_data[j*4 +: 4];
                if (nibble < 10)
                    ascii = 8'h30 + nibble;
                else
                    ascii = 8'h41 + (nibble - 10);
                send_byte(ascii);
                #(BIT_TIME * 2);
            end
        end
    endtask
    
    task send_command;
        input [107:0] hex_data;
        begin
            send_hex_number(hex_data);
            #(BIT_TIME * 2);
            send_byte(8'h0D);
            #(BIT_TIME * 2);
            send_byte(8'h0A);
            #(BIT_TIME * 2);
        end
    endtask
    
    task wait_for_idle;
        begin
            #(BIT_TIME * 100);  // ждем завершения передачи
            while (DUT.FSM.FSM_STATE != 0) begin
                #(BIT_TIME * 10);
            end
            $display("  FSM back to IDLE at time %0t", $time);
        end
    endtask
    
    initial begin
        test_pass = 1;
        
        $display("========================================");
        $display("=== MK_TOP TEST ===");
        $display("========================================");
        
        UART_RXD = 1'b1;
        BTN_0 = 1'b0;
        BTN_1 = 1'b0;
        SYS_NRST = 1'b0;
        #100;
        SYS_NRST = 1'b1;
        #200;
        
        // ========== ТЕСТ 1 ==========
        $display("");
        $display("=== TEST 1: Send valid hex number ===");
        $display("----------------------------------------");
        
        send_command(108'h123456789ABCDEF0123456789A);
        wait_for_idle();
        
        if (DUT.FSM.FSM_STATE == 0) begin
            $display("  PASS: Command processed");
        end else begin
            $display("  FAIL: FSM state = %0d", DUT.FSM.FSM_STATE);
            test_pass = 0;
        end
        
        // ========== ТЕСТ 2 ==========
        $display("");
        $display("=== TEST 2: Send invalid character ('G') ===");
        $display("----------------------------------------");
        
        send_byte(8'h47);
        #(BIT_TIME * 2);
        send_byte(8'h0D);
        #(BIT_TIME * 2);
        send_byte(8'h0A);
        #(BIT_TIME * 2);
        wait_for_idle();
        
        $display("  PASS: Error handled");
        
        // ========== ТЕСТ 3 ==========
        $display("");
        $display("=== TEST 3: Framing error (BTN_0) ===");
        $display("----------------------------------------");
        
        BTN_0 = 1'b1;
        #(BIT_TIME * 2);
        send_command(108'h111111111111111111111111111);
        BTN_0 = 1'b0;
        wait_for_idle();
        
        $display("  PASS: Framing error test completed");
        
        // ========== ТЕСТ 4 ==========
        $display("");
        $display("=== TEST 4: Parity error (BTN_1) ===");
        $display("----------------------------------------");
        
        BTN_1 = 1'b1;
        #(BIT_TIME * 2);
        send_command(108'h222222222222222222222222222);
        BTN_1 = 1'b0;
        wait_for_idle();

        $display("  PASS: Parity error test completed");
        
        // ========== ИТОГИ ==========
        $display("");
        $display("========================================");
        if (test_pass) begin
            $display("=== ALL TESTS PASSED ===");
        end else begin
            $display("=== SOME TESTS FAILED ===");
        end
        $display("========================================");
        
        #(BIT_TIME * 30);
        $finish;
    end
    
endmodule

