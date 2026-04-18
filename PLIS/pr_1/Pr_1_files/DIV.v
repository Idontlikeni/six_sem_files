module LA_DIVIDER #(
    parameter DIV = 2,
    parameter CNT_WDT = 2
) (
    input clk, rst,
    output reg CEO
);
    // wire [$clog2(DIV)-1:0] cnt;
    
    wire [CNT_WDT - 1:0] cnt;


    counter #(.step(1), .mod(DIV)) cntr(
        .clk(clk), 
        .reset(rst), 
        .enable(1'b1), 
        .dir(1'b0), 
        .out(cnt)
    );
    
    always@(posedge clk, posedge rst)
        if(rst)
            CEO = 1'b0;
        else 
            begin 
                if(cnt == 0) 
                    CEO = 1'b1;
                else
                    CEO = 1'b0;
            end
endmodule