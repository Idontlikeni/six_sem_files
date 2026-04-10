module counter#(step = 1, mod = 2, cnt_wdt = 1)(
    input clk, reset, enable, dir,
    output reg [$clog2(mod)-1:0] out
);
    initial
        out = 0;
    always@(posedge clk or posedge reset)
    begin
        if (reset)
            out <= 0;
        else if (enable)
        begin
            if(dir == 0)
                out = (out + step) % mod;
            else
                out = (out - step) % mod;
        end
    end
endmodule