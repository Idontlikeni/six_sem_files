`timescale 1ns / 1ps

module ascii_hex_test();

    reg CLK;
    reg [7:0] ASCII;
    wire [3:0] HEX;
    wire HEX_FLG;
    
    integer i;
    
    MK_DC_ASCII_HEX DUT (
        .ASCII(ASCII),
        .HEX(HEX),
        .HEX_FLG(HEX_FLG)
    );
    
    initial begin
        CLK = 1'b0;
        forever #5 CLK = ~CLK;
    end
    
    initial begin
        ASCII = 8'h00;
        
        // Цифры 1-9
        #100;
        ASCII = 8'h31;  // '1'
        #100;
        ASCII = 8'h32;  // '2'
        #100;
        ASCII = 8'h33;  // '3'
        #100;
        ASCII = 8'h34;  // '4'
        #100;
        ASCII = 8'h35;  // '5'
        #100;
        ASCII = 8'h36;  // '6'
        #100;
        ASCII = 8'h37;  // '7'
        #100;
        ASCII = 8'h38;  // '8'
        #100;
        ASCII = 8'h39;  // '9'
        
        // Буквы A-F
        #100;
        ASCII = 8'h41;  // 'A'
        #100;
        ASCII = 8'h42;  // 'B'
        #100;
        ASCII = 8'h43;  // 'C'
        #100;
        ASCII = 8'h44;  // 'D'
        #100;
        ASCII = 8'h45;  // 'E'
        #100;
        ASCII = 8'h46;  // 'F'
        
        // Буквы a-f
        #100;
        ASCII = 8'h61;  // 'a'
        #100;
        ASCII = 8'h62;  // 'b'
        #100;
        ASCII = 8'h63;  // 'c'
        #100;
        ASCII = 8'h64;  // 'd'
        #100;
        ASCII = 8'h65;  // 'e'
        #100;
        ASCII = 8'h66;  // 'f'
        
        // Не HEX символы
        #100;
        ASCII = 8'h47;  // 'G'
        #100;
        ASCII = 8'h67;  // 'g'
        #100;
        ASCII = 8'h20;  // space
        #100;
        ASCII = 8'h0D;  // CR
        #100;
        ASCII = 8'h0A;  // LF
        
        #200;
        $finish;
    end
    
endmodule