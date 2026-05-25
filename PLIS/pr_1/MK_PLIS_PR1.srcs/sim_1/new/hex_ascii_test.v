`timescale 1ns / 1ps

module hex_ascii_test();

    reg CLK;
    reg [3:0] HEX;
    wire [7:0] ASCII;
    
    integer i;
    
    MK_DC_HEX_ASCII DUT (
        .HEX(HEX),
        .ASCII(ASCII)
    );
    
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end
    
    initial begin
        HEX = 4'h0;
        
        // HEX значения 0-9
        HEX = 4'h0;  // 0
        #100;
        HEX = 4'h1;  // 1
        #100;
        HEX = 4'h2;  // 2
        #100;
        HEX = 4'h3;  // 3
        #100;
        HEX = 4'h4;  // 4
        #100;
        HEX = 4'h5;  // 5
        #100;
        HEX = 4'h6;  // 6
        #100;
        HEX = 4'h7;  // 7
        #100;
        HEX = 4'h8;  // 8
        #100;
        HEX = 4'h9;  // 9
        
        // HEX значения A-F
        #100;
        HEX = 4'hA;  // A
        #100;
        HEX = 4'hB;  // B
        #100;
        HEX = 4'hC;  // C
        #100;
        HEX = 4'hD;  // D
        #100;
        HEX = 4'hE;  // E
        #100;
        HEX = 4'hF;  // F

        #200;
        $finish;
    end
endmodule