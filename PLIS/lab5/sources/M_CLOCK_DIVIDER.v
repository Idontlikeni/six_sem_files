`timescale 1ns / 1ps

module M_CLOCK_DIVIDER #(parameter MOD = 255)(
    input wire clk_in,
    input wire reset,
    output reg clk_out
    );
    reg [$clog2(MOD) - 1 : 0] divider_counter;
    
    initial begin
        clk_out = 1'b0;
        divider_counter = {($clog2(MOD)){1'b0}};
    end
    
    always @(posedge clk_in) begin
        if (reset) begin
            clk_out <= 1'b0;
            divider_counter <= {($clog2(MOD)){1'b0}};
        end else begin
            if (divider_counter == MOD - 1) begin
                clk_out <= 1'b1;
                divider_counter <= {($clog2(MOD)){1'b0}};
            end else begin
                clk_out <= 1'b0;
                divider_counter <= divider_counter + 1'b1;
            end
        end
    end
endmodule
