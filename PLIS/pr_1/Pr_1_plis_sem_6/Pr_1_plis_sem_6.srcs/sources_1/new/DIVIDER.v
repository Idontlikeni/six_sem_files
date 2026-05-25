module DIVIDER #(
    parameter DIV = 100000,
    parameter CNT_WDT = 17
) (
    input CLK, RST,
    output reg CEO
);
    // wire [$clog2(DIV)-1:0] cnt;
    
    wire [CNT_WDT - 1:0] cnt;

    counter #(.step(1), .mod(DIV)) cntr(
        .clk(CLK), 
        .reset(RST), 
        .enable(1'b1), 
        .dir(1'b0), 
        .out(cnt)
    );
    
    always@(posedge CLK, posedge RST)
        if(RST)
            CEO = 1'b0;
        else 
            begin 
                if(cnt == 0) 
                    CEO = 1'b1;
                else
                    CEO = 1'b0;
            end
endmodule