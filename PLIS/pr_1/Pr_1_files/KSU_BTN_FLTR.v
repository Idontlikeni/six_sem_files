`timescale 1ns / 1ps

module M_BTN_FILTER #(parameter SIZE = 4)(
    input wire CLK, RESET, IN_SIGNAL, CLOCK_ENABLE,
    output reg OUT_SIGNAL, OUT_SIGNAL_ENABLE
    );
    
    reg [SIZE - 1 : 0] cnt;
    reg [1:0] IN_SIGNAL_SYNC;
    
    initial begin
        cnt = {(SIZE){1'b0}};
        IN_SIGNAL_SYNC = 2'b00;
        OUT_SIGNAL = 1'b0;
        OUT_SIGNAL_ENABLE = 1'b0;
    end
     
    always @(posedge CLK) begin
        if (RESET) begin
            IN_SIGNAL_SYNC <= 2'b00;
            cnt <= {(SIZE){1'b0}};
            OUT_SIGNAL <= 1'b0;
            OUT_SIGNAL_ENABLE <= 1'b0;
        end
        else begin
            IN_SIGNAL_SYNC <= {IN_SIGNAL_SYNC[0], IN_SIGNAL};
            cnt <= IN_SIGNAL_SYNC[1] ^~ OUT_SIGNAL ? 0 : CLOCK_ENABLE ? cnt + 1 : cnt;
            if((&cnt) & CLOCK_ENABLE)
                OUT_SIGNAL <= IN_SIGNAL_SYNC[1];
            OUT_SIGNAL_ENABLE <= (&cnt) & CLOCK_ENABLE & IN_SIGNAL_SYNC[1];
        end
    end
endmodule

