`timescale 1ns / 1ps

module test_cntr_leds();

    reg CLK;
    reg RST;
    reg S_EX_REQ;
    reg S_ADDR;
    reg [2:0] S_CMD;
    reg [7:0] S_D_WR;
    wire S_EX_ACK;
    wire [7:0] S_D_RD;
    wire [7:0] LED;
    wire [4:0] ADDR;
    reg [7:0] RAM_DATA;
    
    localparam CLK_PERIOD = 10;
    integer test_pass;
    reg [7:0] rd_value;
    
    TT_CNTR_LEDS DUT (
        .CLK(CLK),
        .RST(RST),
        .S_EX_REQ(S_EX_REQ),
        .S_ADDR(S_ADDR),
        .S_CMD(S_CMD),
        .S_D_WR(S_D_WR),
        .S_EX_ACK(S_EX_ACK),
        .S_D_RD(S_D_RD),
        .LED(LED),
        .ADDR(ADDR),
        .DATA(RAM_DATA)
    );

    initial begin
        CLK = 1'b0;
        forever #(CLK_PERIOD/2) CLK = ~CLK;
    end
    
    // Запись в MASK (S_ADDR = 0)
    task write_mask;
        input [7:0] value;
        begin
            @(posedge CLK);
            S_EX_REQ <= 1'b1;
            S_ADDR <= 1'b0;
            S_CMD <= 3'b000;  // IO Write (000)
            S_D_WR <= value;
            @(posedge CLK);
            S_EX_REQ <= 1'b0;
            @(posedge CLK);
        end
    endtask
    
    // Запись в ADDR (S_ADDR = 1)
    task write_addr;
        input [4:0] value;
        begin
            @(posedge CLK);
            S_EX_REQ <= 1'b1;
            S_ADDR <= 1'b1;
            S_CMD <= 3'b000;  // IO Write (000)
            S_D_WR <= {3'b0, value};
            @(posedge CLK);
            S_EX_REQ <= 1'b0;
            @(posedge CLK);
        end
    endtask
    
    // Чтение по адресу (0 = MASK, 1 = ADDR)
    task read_value;
        input addr_sel;
        output [7:0] value;
        begin
            @(posedge CLK);
            S_EX_REQ <= 1'b1;
            S_ADDR <= addr_sel;
            S_CMD <= 3'b100;  // IO Read (100)
            @(posedge CLK);
            value = S_D_RD;
            S_EX_REQ <= 1'b0;
            @(posedge CLK);
        end
    endtask
    
    initial begin
        test_pass = 1;
        RAM_DATA = 8'h00;
        RST = 1'b1;
        S_EX_REQ = 1'b0;
        S_ADDR = 1'b0;
        S_CMD = 3'b000;
        S_D_WR = 8'h00;
        #100;
        RST = 1'b0;
        #100;

        // Тест 1: Запись MASK
        $display("");
        $display("=== TEST 1: Write MASK ===");
        write_mask(8'hAA);
        RAM_DATA = 8'h0F;
        #100;
        
        read_value(1'b0, rd_value);
        $display("MASK = 0x%h (expected 0xAA)", rd_value);
        $display("RAM_DATA = 0x%h", RAM_DATA);
        read_value(1'b1, rd_value);
        $display("S_D_RD = 0x%h (expected 0x00)", rd_value);
        $display("ADDR = 0x%h (expected 0x00)", ADDR);
        $display("LED = 0x%h (expected 0x0A)", LED);
        
        if (LED == 8'h0A) begin
            $display(">>> PASS <<<");
        end else begin
            $display(">>> FAIL <<<");
            test_pass = 0;
        end

        // Тест 2: Запись ADDR
        $display("");
        $display("=== TEST 2: Write ADDR ===");
        write_addr(6'h2A);
        #100;
        
        read_value(1'b0, rd_value);
        $display("MASK = 0x%h (expected 0xAA)", rd_value);
        $display("RAM_DATA = 0x%h", RAM_DATA);
        read_value(1'b1, rd_value);
        $display("S_D_RD = 0x%h (expected 0x2A)", rd_value);
        $display("ADDR = 0x%h (expected 0x2A)", ADDR);
        $display("LED = 0x%h (expected 0x0A)", LED);
        
        if (ADDR == 6'h2A) begin
            $display(">>> PASS <<<");
        end else begin
            $display(">>> FAIL <<<");
            test_pass = 0;
        end
        
        // Тест 3: Изменение MASK
        $display("");
        $display("=== TEST 2: Change MASK ===");
        write_mask(8'h55);
        RAM_DATA = 8'hFF;
        #100;
        
        read_value(1'b0, rd_value);
        $display("MASK = 0x%h (expected 0x55)", rd_value);
        $display("RAM_DATA = 0x%h", RAM_DATA);
        read_value(1'b1, rd_value);
        $display("S_D_RD = 0x%h (expected 0x2A)", rd_value);
        $display("ADDR = 0x%h (expected 0x2A)", ADDR);
        $display("LED = 0x%h (expected 0x55)", LED);
        
        if (LED == 8'h55 && ADDR == 6'h2A) begin
            $display(">>> PASS <<<");
        end else begin
            $display(">>> FAIL: ADDR=0x%h, LED=0x%h <<<", ADDR, LED);
            test_pass = 0;
        end
        
        // Тест 4: Изменение ADDR
        $display("");
        $display("=== TEST 4: Change ADDR ===");
        write_addr(6'h15);
        #100;
        
        read_value(1'b0, rd_value);
        $display("MASK = 0x%h (expected 0x55)", rd_value);
        $display("RAM_DATA = 0x%h", RAM_DATA);
        read_value(1'b1, rd_value);
        $display("S_D_RD = 0x%h (expected 0x15)", rd_value);
        $display("ADDR = 0x%h (expected 0x15)", ADDR);
        $display("LED = 0x%h (expected 0x55)", LED);
        
        if (ADDR == 6'h15 && LED == 8'h55) begin
            $display(">>> PASS <<<");
        end else begin
            $display(">>> FAIL: ADDR=0x%h, LED=0x%h <<<", ADDR, LED);
            test_pass = 0;
        end
        
        $display("");
        if (test_pass) begin
            $display("=== ALL TESTS PASSED ===");
        end else begin
            $display("=== SOME TESTS FAILED ===");
        end
        $display("");
        
        $finish;
    end
endmodule
